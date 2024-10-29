## nearby

> Discover what's nearby

#### Wikipedia API

Sample request for listing nearby places:

```
https://en.wikipedia.org/w/api.php?action=query&list=geosearch&gscoord=36.06264597607677%7C-86.97829706270507&gsradius=10000&gslimit=2&format=json
```

Response:

```
{
  "batchcomplete": "",
  "query":
  {
    "geosearch":
    [
      {
        "pageid": 2060021,
        "ns": 0,
        "title": "WRFN-LP",
        "lat": 36.042,
        "lon": -86.992,
        "dist": 2605.4,
        "primary": ""
      },
      {
        "pageid": 48638124,
        "ns": 0,
        "title": "Smith Farmhouse (Pasquo, Tennessee)",
        "lat": 36.03525,
        "lon": -86.9812,
        "dist": 3057.5,
        "primary": ""
      }
    ]
  }
}
```

Sample request for getting details of a place:

```
https://en.wikipedia.org/w/api.php?action=query&prop=extracts&exintro&explaintext&pageids=2060021&format=json
```

Response:

```
{
  "batchcomplete": "",
  "query":
  {
    "pages":
    {
      "2060021":
      {
        "pageid": 2060021,
        "ns": 0,
        "title": "WRFN-LP",
        "extract": "WRFN-LP is a community LPFM non-commercial radio station in Nashville, Tennessee. It operates at a frequency of 107.1 MHz and is branded as Radio Free Nashville. The station features a mix of music, talk and public affairs programming, almost all with a decidedly liberal or leftist political perspective largely not found on other area media outlets (local or national).\nThe station went on the air in April 2005, with studios and transmitter located at the nearby community of Pasquo, Tennessee, 15 miles (24 km) west of downtown Nashville.\nWRFN-LP was the seventh community radio \"barnraising\" of the Prometheus Radio Project.\nIn mid-2007, WRFN began simulcasting on Nashville's iQtv's second audio program (SAP).\nOn October 25, 2009, WRFN changed its frequency to 107.1 MHz from its previously assigned frequency of 98.9 MHz, which had also been occupied by WANT in nearby Lebanon, Tennessee.\nA translator station, W279CH on 103.7 in Hermitage, Tennessee, signed-on in December 2014 to serve Nashville proper, expanding WRFN's over-the-air reach in the Nashville metro area.\nThe callsign was originally used by another Nashville station, Fisk University's WFSK-FM, from its beginning in 1973 until about 1983."
      }
    }
  }
}
```
