<?xml version="1.0" encoding="UTF-8"?>
<dataStore>
  <name>${datastoreName}</name>
  <type>Shapefile</type>
  <enabled>true</enabled>
  <workspace>
    <name>oztrack</name>
  </workspace>
  <connectionParameters>
    <entry key="filetype">shapefile</entry>
    <entry key="url">${shapefileUrl}</entry>
    <entry key="charset">${shapefileCharset}</entry>
    <#if shapefileTimezone??>
    <entry key="timezone">${shapefileTimezone}</entry>
    </#if>
    <entry key="namespace">${namespaceUri}</entry>
  </connectionParameters>
</dataStore>
