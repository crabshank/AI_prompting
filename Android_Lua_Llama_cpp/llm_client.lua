-- GGUF Model Interface - CORRECT EXTERNAL PATH VERSION
-- Uses the properly built binary from CMake build
-- PRESERVES YOUR EXACT HARDCODED MODEL PATH

local os = require("os")
local io = require("io")

-- Get home directory safely
local home_dir = os.getenv("HOME") or "/data/data/com.termux/files/home"
local llama_bin = home_dir .. "/llama.cpp/build/bin/llama-cli"  -- Most common name

print("📱 Termux environment detected")
print("🏠 Home directory: " .. home_dir)
print("🔧 Using binary: " .. llama_bin)

-- Verify binary exists
local bin_file = io.open(llama_bin, "r")
if not bin_file then
    -- Try alternative names
    local alternatives = {
        home_dir .. "/llama.cpp/build/bin/main",
        home_dir .. "/llama.cpp/build/bin/llama-inference"
    }
    
    for _, alt_bin in ipairs(alternatives) do
        bin_file = io.open(alt_bin, "r")
        if bin_file then
            llama_bin = alt_bin
            print("✅ Found alternative binary: " .. llama_bin)
            bin_file:close()
            break
        end
    end
    
    if not bin_file then
        error("❌ LLAMA BINARY NOT FOUND at: " .. llama_bin .. "\n" ..
              "🔧 Run these commands to build:\n" ..
              "cd ~/llama.cpp\n" ..
              "mkdir -p build\n" ..
              "cd build\n" ..
              "cmake .. -DLLAMA_CURL=ON -DLLAMA_NATIVE=OFF\n" ..
              "cmake --build . -- -j$(nproc)\n" ..
              "\nCommon locations to check:\n" ..
              "ls -la ~/llama.cpp/build/bin/")
    end
end
if bin_file then bin_file:close() end
print("✅ Binary verified: " .. llama_bin)

-- Create client class
local LLMClient = {}
LLMClient.__index = LLMClient

function LLMClient:new(model_path, options)
    options = options or {}
    
    print("\n🆕 Creating external LLM client")
    print("📂 Model path: " .. model_path)
    
    -- Verify model file exists
    local model_file = io.open(model_path, "rb")
    if not model_file then
        error("❌ MODEL FILE NOT FOUND: " .. model_path)
    end
    model_file:close()
    print("✅ Model file exists")
    
    local client = {
        model_path = model_path,
        llama_bin = llama_bin,
        n_ctx = options.n_ctx or 256,       -- Safe default for mobile
        n_threads = options.n_threads or 2,  -- 2 threads max
        max_tokens = options.max_tokens or 64
    }
    
    setmetatable(client, self)
    return client
end

function LLMClient:generate(prompt, max_tokens)
    max_tokens = max_tokens or self.max_tokens
    
    if #prompt > 100 then
        error("❌ Prompt too long. Max 100 characters on mobile.")
    end
    
    print("\n⚡ Generating with external binary...")
    print("📝 Prompt: " .. prompt)
    print("💭 Response:")
    
    -- Escape special characters for shell (simplified for Termux)
    local safe_prompt = prompt:gsub("'", "'\"'\"'")
    local safe_model = self.model_path:gsub("'", "'\"'\"'")
    
    -- Build command with modern llama-cli syntax
    local cmd = string.format(
        "'%s' -m '%s' -n %d -c %d -t %d -p '%s' --no-perf",
        self.llama_bin,
        safe_model,
        max_tokens,
        self.n_ctx,
        self.n_threads,
        safe_prompt
    )
    
    print("🔧 Command: " .. cmd)
    
    -- Execute and stream output
    local handle = io.popen(cmd)
    if not handle then
        error("❌ Failed to execute command")
    end
    
    local response = ""
    for line in handle:lines() do
        -- Skip progress lines and metadata
        if not line:match("^%[") and not line:match("^llama_") and not line:match("^usage:") then
            -- Extract generated text
            local generated = line:gsub("^.*generation]:%s*", "")
            response = response .. generated
            io.write(generated)
            io.flush()
        end
    end
    
    handle:close()
    return response
end

function LLMClient:cleanup()
    print("🧹 External client cleanup (no resources to free)")
end

print("✅ External LLMClient module initialized")
print("💡 Using llama-cli binary from CMake build")
return LLMClient
