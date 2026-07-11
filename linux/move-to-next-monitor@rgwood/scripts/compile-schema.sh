#!/bin/sh
# Compile the GSettings schema for this extension.
# Run this after editing move-to-next-monitor.gschema.xml.
set -e
cd "$(dirname "$0")/.."
glib-compile-schemas --targetdir=schemas schemas
echo "Compiled schemas/"
