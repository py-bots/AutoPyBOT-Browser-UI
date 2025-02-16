import base64

def encode_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
        encoded_content = base64.b64encode(content.encode("utf-8")).decode("utf-8")
        return encoded_content

webui_py_original_encoded = encode_file("web-ui/webui.py.original")
webui_py_template_encoded = encode_file("web-ui/webui.py.template")
webui_py_initial_encoded = encode_file("web-ui/webui.py") # Encode initial webui.py

print(f"WEBUI_PY_ORIGINAL_EMBEDDED = \"{webui_py_original_encoded}\"")
print(f"WEBUI_PY_TEMPLATE_EMBEDDED = \"{webui_py_template_encoded}\"")
print(f"WEBUI_PY_INITIAL_EMBEDDED = \"{webui_py_initial_encoded}\"") # Print the encoded initial webui.py

# Copy the output and replace the placeholders in your bootstrap.py file