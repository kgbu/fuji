# 証明書生成用スクリプト

## ルートCA と 中間CA 作成
mkdir -p root2048/demoCA/newcerts root2048/demoCA/private
mkdir -p interCA/demoCA/newcerts  interCA/demoCA/private
(cd root2048; touch demoCA/index.txt; echo 01 > demoCA/serial)
(cd interCA; touch demoCA/index.txt; echo 01 > demoCA/serial)

# openssl.cnf のパスはよしなに書き換えて
cp /usr/local/etc/openssl/openssl.cnf ./

cd root2048

# ルートCA で自己署名
openssl req -new -newkey rsa:2048 -sha256 \
        -keyout demoCA/private/cakey.pem \
        -out    demoCA/careq.pem \
        -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=root' \
        -passout pass:akane

openssl ca -config ../openssl.cnf \
        -md sha256 \
        -in      demoCA/careq.pem \
        -keyfile demoCA/private/cakey.pem \
        -out     demoCA/cacert.pem \
        -selfsign -days 3650 -extensions v3_ca -batch \
        -passin pass:akane

cd ../interCA

# 中間CA をルートCA で署名
openssl req -new -newkey rsa:2048 -sha256 \
        -keyout demoCA/private/cakey.pem \
        -out    demoCA/careq.pem \
        -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=inter' \
        -passout pass:akane

cd ../root2048

openssl ca -config ../openssl.cnf \
        -md sha256 \
        -in      ../interCA/demoCA/careq.pem \
        -keyfile demoCA/private/cakey.pem \
        -out     ../interCA/demoCA/cacert.pem \
        -days 3650 -extensions v3_ca -batch -policy policy_anything \
        -passin pass:akane

cd ..

# サーバ証明書を中間CAで署名
mkdir server
cd server

openssl genrsa 2048 > server.key
openssl req -new -sha256 \
        -key server.key \
        -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=*' \
        > server.csr

cd ../interCA

openssl ca -config ../openssl.cnf \
        -md sha256 \
        -in      ../server/server.csr \
        -out     ../server/server.crt \
        -keyfile demoCA/private/cakey.pem \
        -cert    demoCA/cacert.pem \
        -batch -policy policy_anything \
        -passin pass:akane

cd ..

# クライアント証明書を中間CAで署名
mkdir client
cd client

openssl genrsa 2048 > client.key
openssl req -new -sha256 \
        -key client.key \
        -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=client' \
        > client.csr

cd ../interCA

openssl ca -config ../openssl.cnf \
        -md sha256 \
        -in      ../client/client.csr \
        -out     ../client/client.crt \
        -keyfile demoCA/private/cakey.pem \
        -cert    demoCA/cacert.pem \
        -batch -policy policy_anything \
        -passin pass:akane

cd ..

cat interCA/demoCA/cacert.pem root2048/demoCA/cacert.pem > ca.pem
cat server/server.crt > server.pem 
cat server/server.key > server.key

cat server/server.crt interCA/demoCA/cacert.pem server/server.key > client.pem

rm -r root2048 interCA server client openssl.cnf
