FROM node AS bundler
WORKDIR /worker
COPY . .

RUN yarn install
RUN npx webpack --mode production

FROM swift AS builder
WORKDIR /worker
COPY --from=bundler /worker .

RUN apt-get update && apt-get install -y libmongoc-1.0-0 libbson-1.0-0 libssl-dev libsqlite3-dev
RUN swift build -c release

RUN export BIN_PATH=$(swift build -c release --show-bin-path)
RUN mkdir release && cp -r $BIN_PATH/ release/

FROM swift:slim
WORKDIR /app
COPY --from=builder /worker/release .

RUN apt-get update && apt-get install -y libmongoc-1.0-0 libbson-1.0-0 libssl-dev libsqlite3-dev

ENTRYPOINT ["./DBBrowser"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0"]