FROM node AS bundler
WORKDIR /worker
COPY . .

RUN yarn install
RUN npx webpack --mode production

FROM swift AS builder

RUN apt-get update \
 && apt-get install -y libmongoc-1.0-0 libbson-1.0-0 libssl-dev libsqlite3-dev libjavascriptcoregtk-4.0-dev \
 && rm -r /var/lib/apt/lists/*

WORKDIR /worker
COPY --from=bundler /worker .

RUN swift build -c release \
 && mkdir app && cp -r "$(swift build -c release --show-bin-path)" app/ \
 && cd app/release \
 && rm -rf *.o \
 && rm -rf *.build \
 && rm -rf *.swiftdoc \
 && rm -rf *.swiftmodule \
 && rm -rf *.swiftsourceinfo \
 && rm -rf *.product \
 && rm -rf ModuleCache \
 && rm -f description.json

FROM swift:slim

RUN apt-get update \
 && apt-get install -y libmongoc-1.0-0 libbson-1.0-0 libssl-dev libsqlite3-dev libjavascriptcoregtk-4.0-dev \
 && rm -r /var/lib/apt/lists/*

WORKDIR /worker/.build/x86_64-unknown-linux-gnu
COPY --from=builder /worker/app .

EXPOSE 8080

ENTRYPOINT ["./release/Server"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0"]
