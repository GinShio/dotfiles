#!/usr/bin/env bash

python3 {{@@ scripts.root_dir @@}}/gputest.py install
python3 {{@@ scripts.root_dir @@}}/gputest.py restore --days 10
