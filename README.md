## Usage:
```shell
git clone https://github.com/popwalker/bmark.git

cd bmark

git clone https://github.com/openresty/lua-resty-string.git
git clone  https://github.com/jkeys089/lua-resty-hmac.git
git clone https://github.com/rxi/json.lua.git && mv json.lua jsonlua

gcc -shared -o libtimestamp.so -fPIC timestamp.c
```