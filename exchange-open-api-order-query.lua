
local hmac = require "resty.hmac"
local json = require("json")
local ffi = require("ffi")
ffi.cdef[[
long long get_millisecond_timestamp();
]]

local timestamp_lib = ffi.load("./libtimestamp.so") 
-- 调用 C 函数
local function get_millisecond_timestamp()
    return tostring(timestamp_lib.get_millisecond_timestamp()):gsub("LL", "")
end


local function to_hex(s)
    local hex_chars = '0123456789abcdef'
    local hex_str = {}
    local len = #s
    for i = 1, len do
        local byte = string.byte(s, i)
        local hi = math.floor(byte / 16) + 1
        local lo = byte % 16 + 1
        hex_str[#hex_str + 1] = hex_chars:sub(hi, hi)
        hex_str[#hex_str + 1] = hex_chars:sub(lo, lo)
    end
    return table.concat(hex_str)
end

-- 生成签名
local function generate_sign(timestamp, method, request_path, query_string, body, secret_key)
    if not secret_key or secret_key == "" or not method or method == "" then
        return ""
    end

    -- 构建预哈希字符串
    local preHashParts = {
        timestamp,
        method:upper(),
        request_path
    }

    -- 正确处理 query_string
    if query_string and query_string ~= "" then
        table.insert(preHashParts, "?" .. query_string)
    end

    -- 如果提供了请求体，加入到预哈希字符串中
    if body and body ~= "" then
        table.insert(preHashParts, body)
    end

    local preHash = table.concat(preHashParts)

    local hmac_sha1 = hmac:new(secret_key, hmac.ALGOS.SHA256)
    if not hmac_sha1 then
        print("hmac new failed, secret_key:", secret_key)
        return
    end

    local ok = hmac_sha1:update(preHash)
    if not ok then
        print("hmac_sha1 update failed, preHash:", preHash)
        return
    end

    local mac = hmac_sha1:final()  -- binary mac

    return to_hex(mac)
end



-- local token = "67c01f11d6b8bcgf13e8bc4674dac556" -- test
-- local secret_key = "b62c27710ebe94g7cb072c07b6015759" -- test
local token = "67c0af11d6b8bcgf13e8bc4674dac556" -- dev
local secret_key = "b62c27710ebe94cccb072c07b6015759" -- dev
local request_path = "/exchange-open-api/api/trade/orders-pending"
local method = "GET"

local counter = {}


function request()
    
    local timestamp = get_millisecond_timestamp()
    local sign = generate_sign(timestamp, method, request_path, "", nil, secret_key)
    local headers = {}
    headers["Content-Type"] = "application/json"
    headers["X_CH_APIKEY"] = token
    headers["X_CH_TS"] = timestamp
    headers["X_CH_SIGN"] = sign

    local req = wrk.format(method, request_path, headers)

    -- 返回修改后的请求
    return req
end

function response(status, header, body)
    local data = json.decode(body)

    -- 检查是否包含你需要的字段，以预防 nil 值错误
    local code = "0"
    if data.code then
        code = data.code
    end

    -- 使用全局变量进行计数
    counter[code] = (counter[code] or 0) + 1

    print("响应body: ", json.encode(data))

    for key, value in pairs(counter) do
        print("Code " .. key .. " count: " .. value)
    end
end

function done(summary, latency, requests)
    io.write("------------------------------\n")
    -- 在done函数中遍历全局计数器并打印计数
    for key, value in pairs(counter) do
        print("Code " .. key .. " count: " .. value)
    end
end
