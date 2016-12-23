#!/bin/bash

find  $HOME/memo/memo/ -size 0 2>/dev/null | xargs rm 2>/dev/null
