print("🚀 Starting test with CORRECT binary path")
local LLMClient = require("llm_client")

-- YOUR EXACT MODEL PATH - CHANGE THIS!
local model_path = "/storage/emulated/0/Documents/AI/Models/apollo2-2b-q4_0.gguf"

print("\n🧠 Creating client...")
local client = nil
local success, err = pcall(function()
    client = LLMClient:new(model_path, {
        n_ctx = 256,
        n_threads = 2,
        max_tokens = 48
    })
end)

if not success then
    print("\n💀 CLIENT CREATION FAILED: " .. tostring(err))
    os.exit(1)
end

print("\n✅ Client created successfully!")
print("🎯 Testing generation with minimal prompt...")

local prompt = "Lua is"
print("\n📝 Prompt: '" .. prompt .. "'")
print("💭 Response:")

local response = client:generate(prompt)

print("\n\n📋 Complete response:")
print(response)

client:cleanup()

print("\n✅ SUCCESS! External method works with CMake-built binary")
print("💡 You can now gradually increase parameters for better results")
