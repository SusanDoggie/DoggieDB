FROM node AS bundler
WORKDIR /worker
COPY . .

RUN yarn install
RUN npx webpack --mode production

FROM swift AS builder

RUN apt-get update && apt-get install -y libmongoc-1.0-0 libbson-1.0-0 libssl-dev libsqlite3-dev

WORKDIR /worker
COPY --from=bundler /worker .

RUN swift build -c release

RUN mkdir release && cp -r "$(swift build -c release --show-bin-path)/" release/

FROM swift:slim

RUN apt-get update && apt-get install -y libmongoc-1.0-0 libbson-1.0-0 libssl-dev libsqlite3-dev

WORKDIR /app
COPY --from=builder /worker/release .

ENTRYPOINT ["./DBBrowser"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0"]