#  KissTNC

To [quote Wikipedia](https://en.wikipedia.org/wiki/KISS_(TNC)):

> KISS (keep it simple, stupid[1]) is a protocol for communicating with a serial terminal node controller (TNC) device used for amateur radio. This allows the TNC to combine more features into a single device and standardizes communications.
 
This framework seeks to enable parsing of a stream of KISS frames into KissFrame objects, and to create KissFrame objects and turn them into a stream of KISS frames.

# Specs

I'm using the following documents, as well as a bunch of frames I've captured off of my Mobilinkd TNC3, to assist developing this library.

* http://www.ax25.net/kiss.aspx
* https://en.wikipedia.org/wiki/KISS_(TNC)
* https://www.tapr.org/pdf/CNC1987-KISS-TNC-K3MC-KA9Q.pdf
