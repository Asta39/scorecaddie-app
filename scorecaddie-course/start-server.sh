#!/bin/bash
# Start ScoreCaddie Course Server
cd /Users/ianlove/workspaces/scorecaddie-app/scorecaddie-course
python3 -m http.server 8080
# Then open: http://localhost:8080