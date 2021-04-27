# DoggieDB

[![Github Actions](https://github.com/SusanDoggie/DoggieDB/workflows/Builder/badge.svg)](https://github.com/SusanDoggie/DoggieDB/actions)
[![codecov](https://codecov.io/gh/SusanDoggie/DoggieDB/branch/main/graph/badge.svg)](https://codecov.io/gh/SusanDoggie/DoggieDB)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg?style=flat)
[![GitHub release](https://img.shields.io/github/release/SusanDoggie/DoggieDB.svg)](https://github.com/SusanDoggie/DoggieDB/releases)
[![Swift](https://img.shields.io/badge/swift-5.3-orange.svg?style=flat)](https://swift.org)
[![MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

## Introduction

DoggieDB provides a set of modules include different database drivers.

## System Requirements

For linux platforms, you need to install some of database drivers.

### Ubuntu

#### MongoDB

    apt-get -y install libmongoc-1.0-0 libbson-1.0-0 libssl-dev

#### SQLite

    apt-get -y install libsqlite3-dev

### CentOS 8

#### MongoDB

    yum -y install mongo-c-driver libbson openssl-devel

#### SQLite

    yum -y install sqlite-devel

### Amazon Linux 2

#### MongoDB

    yum -y install mongo-c-driver libbson openssl-devel

#### SQLite

    yum -y install sqlite-devel
