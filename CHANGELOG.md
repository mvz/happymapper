## 0.5.9 / 2014-02-18

* Correctly output boolean element value 'false'  (confusion)

## 0.5.8 / 2013-10-12

* Allow child elements to remove their parent's namespacing (dcarneiro)
* has_many elements were returning nil because the tag name was being ignored (haarts)
* Subclassed happymapper classes are allowed to override elements (benoist)
* Attributes on elements with dashes will properly created methods (alex-klepa)
* 'Embedded' attributes break parsing when parent element is not present (geoffwa)

## 0.5.7 / 2012-10-29

## 0.5.6 / 2012-10-29

* Add possibility to give a configuration block to Nokogiri when parsing (DieboldInc).

## 0.5.5 / 2012-09-30

* Fix for Boolean attributes to ensure that they parse correctly (zrob)

## 0.5.4/ 2012-09-25

* the #wrap method allows you to better model xml content that is buried deep
  within the xml. This implementation addresses issues with calling #to_xml
  with content that was parsed from an xpath. (zrob)

* Parent HappyMapper classes may dictate the name of the tag for the child
  HappyMapper instances. (zrob)

## 0.5.3/ 2012-09-23

* String is the default type for parsed fields. (crv)
* Update the attributes of an existing HappyMapper instance with new XML (benoist)