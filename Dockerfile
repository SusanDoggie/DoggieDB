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

RUN mkdir app && cp -r "$(swift build -c release --show-bin-path)" app/

FROM swift:slim

RUN apt-get update && apt-get install -y libmongoc-1.0-0 libbson-1.0-0 libssl-dev libsqlite3-dev

WORKDIR /app
COPY --from=builder /worker/app .

EXPOSE 8080

ENTRYPOINT ["./release/DBBrowser"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0"]
