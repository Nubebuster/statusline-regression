#!/bin/bash
# Minimal OSC 8 test - ONLY outputs a single hyperlink, nothing else
printf '\e]8;;toclipboard://test-uuid\e\\uuid\e]8;;\e\\'
