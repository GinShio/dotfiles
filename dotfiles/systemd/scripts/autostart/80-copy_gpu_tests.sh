#!/usr/bin/env bash

python3 {{@@ projects.script_dir @@}}/gputest.py install
python3 {{@@ projects.script_dir @@}}/gputest.py restore --days 10
