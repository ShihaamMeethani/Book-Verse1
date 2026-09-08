import json
import os
from groq import Groq

from .system_prompt import SYSTEM_PROMPT
from . import firestore_tools as ft

client = Groq(api_key=os.environ["GROQ_API_KEY"])

# llama-3.3-70b-versatile is Groq's current recommended model for reliable
# tool/function calling. If you hit a "model_decommissioned" error, check
# console.groq.com/docs/models for the current replacement id.
MODEL = "openai/gpt-oss-120b"

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "search_books",
            "description": "Search the BookVerse catalog. Use for browsing, discovery, or recommendations.",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string"},
                    "genre": {"type": "string"},
                    "max_price": {"type": "number"},
                    "free_only": {"type": "boolean"},
                    "sort_by": {"type": "string", "enum": ["price_low", "price_high", "rating", "newest"]},
                    "limit": {"type": "integer"},
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_book_details",
            "description": "Get full details for one specific book by id or exact title.",
            "parameters": {
                "type": "object",
                "properties": {"book_id": {"type": "string"}, "title": {"type": "string"}},
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_user_orders",
            "description": "Get the current user's own order history or one specific order's status.",
            "parameters": {
                "type": "object",
                "properties": {"order_id": {"type": "string"}},
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_app_faq",
            "description": "Look up a static help topic.",
            "parameters": {
                "type": "object",
                "properties": {"topic": {"type": "string", "enum": list(ft._FAQ.keys())}},
                "required": ["topic"],
            },
        },
    },
]


def _run_tool(name: str, tool_input: dict, verified_uid: str):
    """`verified_uid` always comes from the server-verified token (auth.py),
    never from tool_input the model produced -- this is intentional."""
    if name == "search_books":
        return ft.search_books(**tool_input)
    if name == "get_book_details":
        return ft.get_book_details(**tool_input)
    if name == "get_user_orders":
        return ft.get_user_orders(user_id=verified_uid, order_id=tool_input.get("order_id", ""))
    if name == "get_app_faq":
        return ft.get_app_faq(tool_input["topic"])
    return {"error": f"unknown_tool:{name}"}


def chat(user_message: str, verified_uid: str, current_cart: list[dict] | None,
         history: list[dict] | None = None, max_tool_rounds: int = 4) -> str:
    """One turn of the conversation. `history` is a list of prior
    {"role": ..., "content": ...} messages you persist per session_id
    (e.g. in Firestore or Redis) between requests."""
    cart_block = f"\nCURRENT_CART: {current_cart or []}\n"

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    messages.extend(history or [])
    messages.append({"role": "user", "content": user_message + cart_block})

    for _ in range(max_tool_rounds):
        response = client.chat.completions.create(
            model=MODEL,
            max_tokens=1024,
            messages=messages,
            tools=TOOLS,
            tool_choice="auto",
        )
        message = response.choices[0].message

        if not message.tool_calls:
            return message.content or ""

        messages.append({
            "role": "assistant",
            "content": message.content,
            "tool_calls": [
                {
                    "id": tc.id,
                    "type": "function",
                    "function": {"name": tc.function.name, "arguments": tc.function.arguments},
                }
                for tc in message.tool_calls
            ],
        })

        for tc in message.tool_calls:
            try:
                args = json.loads(tc.function.arguments or "{}")
            except json.JSONDecodeError:
                args = {}
            result = _run_tool(tc.function.name, args, verified_uid)
            messages.append({
                "role": "tool",
                "tool_call_id": tc.id,
                "name": tc.function.name,
                "content": str(result),
            })

    return "Sorry, I couldn't finish looking that up. Please try again."
