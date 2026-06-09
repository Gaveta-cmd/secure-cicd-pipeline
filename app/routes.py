from flask import Blueprint, jsonify, request, abort
import re

main = Blueprint("main", __name__)

VALID_ITEM_ID = re.compile(r"^[a-zA-Z0-9_-]{1,64}$")


@main.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "version": "1.0.0"})


@main.route("/items", methods=["GET"])
def list_items():
    items = [
        {"id": "1", "name": "Widget A", "category": "hardware"},
        {"id": "2", "name": "Widget B", "category": "software"},
    ]
    return jsonify({"items": items, "count": len(items)})


@main.route("/items/<item_id>", methods=["GET"])
def get_item(item_id):
    if not VALID_ITEM_ID.match(item_id):
        abort(400, description="Invalid item ID format")

    if item_id == "1":
        return jsonify({"id": "1", "name": "Widget A", "category": "hardware"})

    abort(404, description=f"Item {item_id} not found")


@main.route("/items", methods=["POST"])
def create_item():
    data = request.get_json(silent=True)
    if not data:
        abort(400, description="Request body must be valid JSON")

    name = data.get("name", "").strip()
    category = data.get("category", "").strip()

    if not name or len(name) > 128:
        abort(400, description="Field 'name' is required and must be ≤ 128 characters")
    if not category:
        abort(400, description="Field 'category' is required")

    new_item = {"id": "3", "name": name, "category": category}
    return jsonify(new_item), 201

