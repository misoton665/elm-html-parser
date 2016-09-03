module Tests exposing (..)

import String
import Combine as RawParser exposing (..)
import HtmlParser as HtmlParser exposing (..)
import HtmlParser.Search as Search
import ElmTest exposing (..)


testParse : String -> Node -> Assertion
testParse s ast =
  assertEqual (Ok ast) (HtmlParser.parseOne s)


testParseComplex : (List Node -> Bool) -> String -> Assertion
testParseComplex f s =
  case HtmlParser.parse s of
    Ok nodes ->
      assert (f nodes)

    Err e ->
      ElmTest.fail (toString e)


textNodeTests : Test
textNodeTests =
  suite "TextNode"
    [ test "basic" (testParse "1" (Text "1"))
    , test "basic" (testParse "a" (Text "a"))
    , test "basic" (testParse "1a" (Text "1a"))
    , test "decode" (testParse "&amp;" (Text "&"))
    , test "decode" (testParse "&lt;" (Text "<"))
    , test "decode" (testParse "&gt;" (Text ">"))
    , test "decode" (testParse "&nbsp;" (Text " "))
    , test "decode" (testParse "&#38;" (Text "&"))
    , test "decode" (testParse "&#x26;" (Text "&"))
    , test "decode" (testParse "&#x3E;" (Text ">"))
    , test "decode" (testParse "&#383;" (Text "ſ"))
    , test "decode" (testParse "&nbsp;" (Text " "))
    , test "decode" (testParse "&nbsp;&nbsp;" (Text "  "))
    , test "decode" (testParse "a&nbsp;b" (Text "a b"))
    , test "decode" (testParse "a&nbsp;&nbsp;b" (Text "a  b"))
    , test "decode" (testParse "&#20;" (Text "&#20;"))
    , test "decode" (testParse """<img alt="&lt;">""" (Element "img" [("alt", "<")] []))
    ]


nodeTests : Test
nodeTests =
  suite "Node"
    [ test "basic" (testParse "<a></a>" (Element "a" [] []))
    , test "basic" (testParse " <a></a> " (Element "a" [] []))
    , test "basic" (testParse "<A></A>" (Element "a" [] []))
    , test "basic" (testParse "<a>a</a>" (Element "a" [] [ Text "a" ]))
    , test "basic" (testParse "<a> a </a>" (Element "a" [] [ Text " a " ]))
    , test "basic" (testParse "<a />" (Element "a" [] []))
    , test "basic" (testParse "<br />" (Element "br" [] []))
    , test "basic" (testParse "<a><a></a></a>" (Element "a" [] [ Element "a" [] [] ]))
    , test "basic" (testParse "<a> <a> </a> </a>" (Element "a" [] [ Text " ", Element "a" [] [ Text " " ], Text " " ]))
    , test "basic" (testParse "<a><a/></a>" (Element "a" [] [ Element "a" [] [] ]))
    , test "basic" (testParse "<a> <br /> </a>" (Element "a" [] [ Text " ", Element "br" [] [], Text " " ]))
    , test "basic" (testParse "<a><a></a><a></a></a>" (Element "a" [] [ Element "a" [] [], Element "a" [] [] ]))
    , test "basic" (testParse "<a><a><a></a></a></a>" (Element "a" [] [ Element "a" [] [ Element "a" [] [] ] ]))
    , test "basic" (testParse "<a><a></a><b></b></a>" (Element "a" [] [ Element "a" [] [], Element "b" [] [] ]))
    , test "basic" (testParse "<h1></h1>" (Element "h1" [] []))
    , test "basic" (testParse "<custom-element></custom-element>" (Element "custom-element" [] []))
    , test "start-only-tag" (testParse "<br>" (Element "br" [] []))
    , test "start-only-tag" (testParse "<BR>" (Element "br" [] []))
    , test "start-only-tag" (testParse "<a> <br> </a>" (Element "a" [] [ Text " ", Element "br" [] [], Text " " ]))
    , test "start-only-tag" (testParse "<a><br><br></a>" (Element "a" [] [ Element "br" [] [], Element "br" [] [] ]))
    , test "start-only-tag" (testParse "<a><br><img><hr><meta></a>" (Element "a" [] [ Element "br" [] [], Element "img" [] [], Element "hr" [] [], Element "meta" [] [] ]))
    , test "start-only-tag" (testParse "<a>foo<br>bar</a>" (Element "a" [] [ Text "foo", Element "br" [] [], Text "bar" ]))
    ]


optionalEndTagTests : Test
optionalEndTagTests =
  suite "OptionalEndTag"
    [ test "ul" (testParse "<ul><li></li></ul>" (Element "ul" [] [ Element "li" [] [] ]))
    , test "ul" (testParse "<ul><li></ul>" (Element "ul" [] [ Element "li" [] [] ]))
    , test "ul" (testParse "<ul><li><li></ul>" (Element "ul" [] [ Element "li" [] [], Element "li" [] [] ]))
    , test "ul" (testParse "<ul><li></li><li></ul>" (Element "ul" [] [ Element "li" [] [], Element "li" [] [] ]))
    , test "ul" (testParse "<ul><li><li></li></ul>" (Element "ul" [] [ Element "li" [] [], Element "li" [] [] ]))
    , test "ul" (testParse "<ul><li><ul></ul></ul>" (Element "ul" [] [ Element "li" [] [ Element "ul" [] [] ] ]))
    , test "ul" (testParse "<ul> <li> <li> </ul>" (Element "ul" [] [ Text " ", Element "li" [] [ Text " " ], Element "li" [] [ Text " " ] ]))
    , test "ol" (testParse "<ol><li></ol>" (Element "ol" [] [ Element "li" [] [] ]))
    , test "tr" (testParse "<tr><td></tr>" (Element "tr" [] [ Element "td" [] [] ]))
    , test "tr" (testParse "<tr><td><td></tr>" (Element "tr" [] [ Element "td" [] [], Element "td" [] [] ]))
    , test "tr" (testParse "<tr><th></tr>" (Element "tr" [] [ Element "th" [] [] ]))
    , test "tr" (testParse "<tr><th><th></tr>" (Element "tr" [] [ Element "th" [] [], Element "th" [] [] ]))
    , test "tr" (testParse "<tr><th><td></tr>" (Element "tr" [] [ Element "th" [] [], Element "td" [] [] ]))
    , test "tr" (testParse "<tr><td><th></tr>" (Element "tr" [] [ Element "td" [] [], Element "th" [] [] ]))
    , test "tbody" (testParse "<tbody><tr><td></tbody>" (Element "tbody" [] [ Element "tr" [] [ Element "td" [] [] ] ]))
    , test "tbody" (testParse "<tbody><tr><th><td></tbody>" (Element "tbody" [] [ Element "tr" [] [ Element "th" [] [], Element "td" [] [] ] ]))
    , test "tbody" (testParse "<tbody><tr><td><tr><td></tbody>" (Element "tbody" [] [ Element "tr" [] [ Element "td" [] [] ], Element "tr" [] [ Element "td" [] [] ] ]))
    , test "tbody" (testParse "<tbody><tr><th><td><tr><th><td></tbody>" (Element "tbody" [] [ Element "tr" [] [ Element "th" [] [], Element "td" [] [] ], Element "tr" [] [ Element "th" [] [], Element "td" [] [] ] ]))
    , test "table" (testParse "<table><caption></table>" (Element "table" [] [ Element "caption" [] [] ]))
    , test "table" (testParse "<table><caption><col></table>" (Element "table" [] [ Element "caption" [] [], Element "col" [] [] ]))
    , test "table" (testParse "<table><caption><colgroup><col></table>" (Element "table" [] [ Element "caption" [] [], Element "colgroup" [] [ Element "col" [] [] ] ]))
    , test "table" (testParse "<table><colgroup><col></table>" (Element "table" [] [ Element "colgroup" [] [ Element "col" [] [] ] ]))
    ]


scriptTests : Test
scriptTests =
  suite "Script"
    [ test "script" (testParse """<script></script>""" (Element "script" [] []))
    , test "script" (testParse """<SCRIPT></SCRIPT>""" (Element "script" [] []))
    , test "script" (testParse """<script src="script.js">foo</script>""" (Element "script" [("src", "script.js")] [ Text "foo" ]))
    , test "script" (testParse """<script>var a = 0 < 1; b = 1 > 0;</script>""" (Element "script" [] [ Text "var a = 0 < 1; b = 1 > 0;" ]))
    , test "script" (testParse """<script><!----></script>""" (Element "script" [] [ Comment "" ]))
    , test "script" (testParse """<script>a<!--</script><script>-->b</script>""" (Element "script" [] [ Text "a", Comment "</script><script>", Text "b" ]))
    , test "style" (testParse """<style>a<!--</style><style>-->b</style>""" (Element "style" [] [ Text "a", Comment "</style><style>", Text "b" ]))
    ]


commentTests : Test
commentTests =
  suite "Comment"
    [ test "basic" (testParse """<!---->""" (Comment ""))
    , test "basic" (testParse """<!--foo\t\r\n -->""" (Comment "foo\t\r\n "))
    , test "basic" (testParse """<!--<div></div>-->""" (Comment "<div></div>"))
    , test "basic" (testParse """<div><!--</div>--></div>""" (Element "div" [] [ Comment "</div>" ]))
    , test "basic" (testParse """<!--<!---->""" (Comment "<!--"))
    ]


attributeTests : Test
attributeTests =
  suite "Attribute"
    [ test "basic" (testParse """<a href="example.com"></a>""" (Element "a" [("href", "example.com")] []))
    , test "basic" (testParse """<a href='example.com'></a>""" (Element "a" [("href", "example.com")] []))
    , test "basic" (testParse """<a href=example.com></a>""" (Element "a" [("href", "example.com")] []))
    , test "basic" (testParse """<a HREF=example.com></a>""" (Element "a" [("href", "example.com")] []))
    , test "basic" (testParse """<a href=bare></a>""" (Element "a" [("href", "bare")] []))
    , test "basic" (testParse """<a href="example.com"/>""" (Element "a" [("href", "example.com")] []))
    , test "basic" (testParse """<input max=100 min = 10.5>""" (Element "input" [("max", "100"), ("min", "10.5")] []))
    , test "basic" (testParse """<input max=100 min = 10.5 />""" (Element "input" [("max", "100"), ("min", "10.5")] []))
    , test "basic" (testParse """<input disabled>""" (Element "input" [("disabled", "")] []))
    , test "basic" (testParse """<input DISABLED>""" (Element "input" [("disabled", "")] []))
    , test "basic" (testParse """<input disabled />""" (Element "input" [("disabled", "")] []))
    , test "basic" (testParse """<meta http-equiv=Content-Type>""" (Element "meta" [("http-equiv", "Content-Type")] []))
    , test "basic" (testParse """<html xmlns:v="urn:schemas-microsoft-com:vml"></html>""" (Element "html" [("xmlns:v", "urn:schemas-microsoft-com:vml")] []))
    ]


intergrationTests : Test
intergrationTests =
  suite "Integration"
    [ test "table" (testParseComplex (\nodes -> (List.length <| Search.getElementsByTagName "td" nodes) == 15) fullOmission)
    , test "table" (testParseComplex (\nodes -> (List.length <| Search.getElementsByTagName "td" nodes) == 18) clipboardFromExcel2013)
    , test "table" (testParseComplex (\nodes -> (List.length <| Search.getElementsByTagName "td" nodes) == 18) clipboardFromOpenOfficeCalc)
    ]


fullOmission : String
fullOmission = """
  <table>
   <caption>37547 TEE Electric Powered Rail Car Train Functions (Abbreviated)
   <colgroup><col><col><col>
   <thead>
    <tr> <th>Function                              <th>Control Unit     <th>Central Station
   <tbody>
    <tr> <td>Headlights                            <td>✔                <td>✔
    <tr> <td>Interior Lights                       <td>✔                <td>✔
    <tr> <td>Electric locomotive operating sounds  <td>✔                <td>✔
    <tr> <td>Engineer's cab lighting               <td>                 <td>✔
    <tr> <td>Station Announcements - Swiss         <td>                 <td>✔
  </table>
  """


clipboardFromExcel2013 : String
clipboardFromExcel2013 = """
  <body link="#0563C1" vlink="#954F72">

  <table border=0 cellpadding=0 cellspacing=0 width=216 style='border-collapse:
   collapse;width:162pt'>
  <!--StartFragment-->
   <col width=72 span=3 style='width:54pt'>
   <tr height=18 style='height:13.5pt'>
    <td height=18 align=right width=72 style='height:13.5pt;width:54pt'>1</td>
    <td align=right width=72 style='width:54pt'>2</td>
    <td align=right width=72 style='width:54pt'>3</td>
   </tr>
   <tr height=18 style='height:13.5pt'>
    <td height=18 class=xl69 align=right style='height:13.5pt'>2</td>
    <td class=xl66 align=right>3</td>
    <td align=right>4</td>
   </tr>
   <tr height=18 style='height:13.5pt'>
    <td height=18 class=xl65 align=right style='height:13.5pt'>3</td>
    <td class=xl66 align=right>4</td>
    <td class=xl65 align=right>5</td>
   </tr>
   <tr height=18 style='height:13.5pt'>
    <td height=18 class=xl65 align=right style='height:13.5pt'>4</td>
    <td class=xl66 align=right>5</td>
    <td class=xl65 align=right>6</td>
   </tr>
   <tr height=18 style='height:13.5pt'>
    <td height=18 class=xl67 align=right style='height:13.5pt'>5</td>
    <td class=xl67 align=right>6</td>
    <td class=xl67 align=right>7</td>
   </tr>
   <tr height=18 style='height:13.5pt'>
    <td height=18 class=xl68 align=right style='height:13.5pt'>6</td>
    <td class=xl68 align=right>7</td>
    <td class=xl68 align=right>8</td>
   </tr>
  <!--EndFragment-->
  </table>

  </body>
  """

clipboardFromOpenOfficeCalc : String
clipboardFromOpenOfficeCalc = """
  <BODY TEXT="#000000">
  <TABLE FRAME=VOID CELLSPACING=0 COLS=3 RULES=NONE BORDER=0>
    <COLGROUP><COL WIDTH=86><COL WIDTH=86><COL WIDTH=86></COLGROUP>
      <TBODY>
          <TR>
              <TD WIDTH=86 HEIGHT=19 ALIGN=RIGHT VALIGN=MIDDLE SDVAL="1" SDNUM="1041;"><FONT COLOR="#000000">1</FONT></TD>
              <TD WIDTH=86 ALIGN=CENTER VALIGN=MIDDLE SDVAL="2" SDNUM="1041;"><FONT COLOR="#000000">2</FONT></TD>
              <TD WIDTH=86 ALIGN=RIGHT VALIGN=MIDDLE SDVAL="3" SDNUM="1041;"><FONT COLOR="#000000">3</FONT></TD>
          </TR>
          <TR>
              <TD HEIGHT=19 ALIGN=LEFT VALIGN=MIDDLE SDVAL="2" SDNUM="1041;"><FONT COLOR="#000000">2</FONT></TD>
              <TD ALIGN=CENTER VALIGN=MIDDLE SDVAL="3" SDNUM="1041;"><B><FONT COLOR="#000000">3</FONT></B></TD>
              <TD ALIGN=RIGHT VALIGN=MIDDLE SDVAL="4" SDNUM="1041;"><B><FONT COLOR="#000000">4</FONT></B></TD>
          </TR>
          <TR>
              <TD HEIGHT=19 ALIGN=LEFT VALIGN=MIDDLE BGCOLOR="#FFFF00" SDVAL="3" SDNUM="1041;"><FONT COLOR="#000000">3</FONT></TD>
              <TD ALIGN=CENTER VALIGN=MIDDLE BGCOLOR="#FFFF00" SDVAL="4" SDNUM="1041;"><B><FONT COLOR="#000000">4</FONT></B></TD>
              <TD ALIGN=RIGHT VALIGN=MIDDLE BGCOLOR="#FFFF00" SDVAL="5" SDNUM="1041;"><B><FONT COLOR="#000000">5</FONT></B></TD>
          </TR>
          <TR>
              <TD HEIGHT=19 ALIGN=LEFT VALIGN=MIDDLE BGCOLOR="#FFFF00" SDVAL="4" SDNUM="1041;"><FONT COLOR="#000000">4</FONT></TD>
              <TD ALIGN=CENTER VALIGN=MIDDLE BGCOLOR="#FFFF00" SDVAL="5" SDNUM="1041;"><FONT COLOR="#000000">5</FONT></TD>
              <TD ALIGN=RIGHT VALIGN=MIDDLE BGCOLOR="#FFFF00" SDVAL="6" SDNUM="1041;"><FONT COLOR="#000000">6</FONT></TD>
          </TR>
          <TR>
              <TD HEIGHT=19 ALIGN=LEFT VALIGN=MIDDLE BGCOLOR="#FFFF00" SDVAL="5" SDNUM="1041;"><FONT COLOR="#000000">5</FONT></TD>
              <TD ALIGN=CENTER VALIGN=MIDDLE BGCOLOR="#FFFF00" SDVAL="6" SDNUM="1041;"><FONT COLOR="#000000">6</FONT></TD>
              <TD ALIGN=RIGHT VALIGN=MIDDLE BGCOLOR="#FFFF00" SDVAL="7" SDNUM="1041;"><FONT COLOR="#000000">7</FONT></TD>
          </TR>
          <TR>
              <TD HEIGHT=19 ALIGN=RIGHT VALIGN=MIDDLE SDVAL="6" SDNUM="1041;"><FONT COLOR="#000000">6</FONT></TD>
              <TD ALIGN=CENTER VALIGN=MIDDLE SDVAL="7" SDNUM="1041;"><FONT COLOR="#000000">7</FONT></TD>
              <TD ALIGN=RIGHT VALIGN=MIDDLE SDVAL="8" SDNUM="1041;"><FONT COLOR="#000000">8</FONT></TD>
          </TR>
      </TBODY>
  </TABLE>
  </BODY>
  """


tests : Test
tests =
  suite "HtmlParser"
    [ textNodeTests
    , nodeTests
    , optionalEndTagTests
    , scriptTests
    , commentTests
    , attributeTests
    , intergrationTests
    ]


main : Program Never
main =
  runSuite tests
