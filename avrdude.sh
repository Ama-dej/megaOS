avrdude -c avrisp -v -V -c arduino -p m328p -P $1 -b 115200 -U $2 -F
