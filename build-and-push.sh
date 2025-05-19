#!/bin/bash

docker build -t jigglyy/frontend ./frontend
docker push jigglyy/frontend

docker build -t jigglyy/backend ./backend
docker push jigglyy/backend
