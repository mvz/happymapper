
HappyMapper
===========

Object to XML mapping library.

This project is a grandchild (a fork of a fork) of the great work done first
by [jnunemaker](https://github.com/jnunemaker/happymapper) and then by
[dam5s](http://github.com/dam5s/happymapper/).


Installation
------------

*Build the gem yourself:*

    $ git clone https://github.com/burtlo/happymapper
    $ cd happymapper
    $ git checkout unhappymapper-nokogiri
    $ gem build nokogiri-happymapper.gemspec
    $ gem install --local happymapper-X.X.X.gem

*For you [Bundler's](http://gembundler.com/) out there, you can add it to your Gemfile and then `bundle install`*

    gem 'nokogiri-happymapper', :git => "git://github.com/burtlo/happymapper.git", :branch => 'unhappymapper-nokogiri'


Differences
-----------

  * [dam5s](http://github.com/dam5s/happymapper/)'s fork added [Nokogiri](http://nokogiri.org/) support
  * `#to_xml` support utilizing the same HappyMapper tags
  * Fixes for [namespaces when using composition of classes](https://github.com/burtlo/happymapper/commit/fd1e898c70f7289d2d2618d629b56f2f6623785c)
  * Fixes for instances of XML where a [namespace is defined but no elements with that namespace are found](https://github.com/burtlo/happymapper/commit/9614221a80ff3bda18ff859aa751dff29cf52fd3). 


Examples
--------

## Element Mapping

Let's start with a simple example to get our feet wet. Here we have a simple example of XML that defines some address information:

    <address>
      <street>Milchstrasse</street>
      <housenumber>23</housenumber>
      <postcode>26131</postcode>
      <city>Oldenburg</city>
      <country code="de">Germany</country>
    </address>

Happymapper will let you easily model this information as a class:

    require 'happymapper'

    class Address
      include HappyMapper

      tag 'address'
      element :street, String, :tag => 'street'
      element :postcode, String, :tag => 'postcode'
      element :housenumber, Integer, :tag => 'housenumber'
      element :city, String, :tag => 'city'
      element :country, String, :tag => 'country'
    end

To make a class HappyMapper compatible you simply `include HappyMapper` within the class definition. This takes care of all the work of defining all the speciality methods and magic you need to get running. As you can see we immediately start using these methods.

* `tag` matches the name of the XML tag name 'address'.

* `element` defines accessor methods for the specified symbol (e.g. `:street`,`:housenumber`) that will return the class type (e.g. `String`,`Integer`) of the XML tag specified (e.g. `:tag => 'street'`, `:tag => 'housenumber'`).
    
When you define an element with an accessor with the same name as the tag, this is the case for all the examples above, you can omit the `:tag`. These two element declaration are equivalent to each other:

    element :street, String, :tag => 'street'
    element :street, String

Including the additional tag element is not going to hurt anything and in some cases will make it absolutely clear how these elements map to the XML. However, once you know this rule, it is hard not to want to save yourself the keystrokes.

Instead of `element` you may also use `has_one`:

    element :street, String, :tag => 'street'
    element :street, String
    has_one :street, String

These three statements are equivalent to each other.

## Parsing

With the mapping of the address XML articulated in our Address class it is time to parse the data:

    address = Address.parse(ADDRESS_XML_DATA, :single => true)
    puts address.street 

Assuming that the constant `ADDRESS_XML_DATA` contains a string representation of the address XML data this is fairly straight-forward save for the `parse` method.

The `parse` method, like `tag` and `element` are all added when you included HappyMapper in the class. Parse is a wonderful, magical place that converts all these declarations that you have made into the data structure you are about to know and love.

But what about the `:single => true`? Right, that is because by default when your object is all done parsing it will be an array. In this case an array with one element, but an array none the less. So the following are equivalent to each other:

    address = Address.parse(ADDRESS_XML_DATA).first
    address = Address.parse(ADDRESS_XML_DATA, :single => true)

The first one returns an array and we return the first instance, the second will do that work for us inside of parse.

## Multiple Elements Mapping

What if our address XML was a little different, perhaps we allowed multiple streets:

    <address>
      <street>Milchstrasse</street>
      <street>Another Street</street>
      <housenumber>23</housenumber>
      <postcode>26131</postcode>
      <city>Oldenburg</city>
      <country code="de">Germany</country>
    </address>

Similar to `element` or `has_one`, the declaration for when you have multiple elements you simply use:

    has_many :street, String, :tag => 'street'

Your resulting `street` method will now return an array.

    address = Address.parse(ADDRESS_XML_DATA, :single => true)
    puts address.street.join('\n')
    
Imagine that you have to write `street.join('\n')` for the rest of eternity throughout your code. It would be a nightmare and one that you could avoid by creating your own convenience method.

     require 'happymapper'

     class Address
       include HappyMapper

       tag 'address'
       
       has_many :street, String
       
       def street
         @street.join('\n')
       end
       
       element :postcode, String, :tag => 'postcode'
       element :housenumber, String, :tag => 'housenumber'
       element :city, String, :tag => 'city'
       element :country, String, :tag => 'country'
     end

Now when we call the method `street` we get a single value, but we still have the instance variable `@street` if we ever need to the values as an array.


## Attribute Mapping

    <address location='home'>
      <street>Milchstrasse</street>
      <street>Another Street</street>
      <housenumber>23</housenumber>
      <postcode>26131</postcode>
      <city>Oldenburg</city>
      <country code="de">Germany</country>
    </address>

Attributes are absolutely the same as `element` or `has_many`

    attribute :location, String, :tag => 'location
    
Again, you can omit the tag if the attribute accessor symbol matches the name of the attribute.


## Class composition (and Text Node)

Our address has a country and that country element has a code. Up until this point we neglected it as we declared a `country` as being a `String`.

    <address location='home'>
      <street>Milchstrasse</street>
      <street>Another Street</street>
      <housenumber>23</housenumber>
      <postcode>26131</postcode>
      <city>Oldenburg</city>
      <country code="de">Germany</country>
    </address>

Well if we only going to parse country, on it's own, we would likely create a class mapping for it.

    class Country
      include HappyMapper
  
      tag 'country'
  
      attribute :code, String
      text_node :name, String
    end

We are utilizing an `attribute` declaration and a new declaration called `text_node`.

* `text_node` is used when you want the text contained within the element

Awesome, now if we were to redeclare our `Address` class we would use our new `Country` class.

    class Address
      include HappyMapper

      tag 'address'
  
      has_many :street, String
  
      def street
        @street.join('\n')
      end
  
      element :postcode, String, :tag => 'postcode'
      element :housenumber, String, :tag => 'housenumber'
      element :city, String, :tag => 'city'
      element :country, Country, :tag => 'country'
    end
  
Instead of `String`, `Boolean`, or `Integer` we say that it is a `Country` and HappyMapper takes care of the details of continuing the XML mapping through the country element.

    address = Address.parse(ADDRESS_XML_DATA, :single => true)
    puts address.country.code
  
A quick note, in the above example we used the constant `Country`. We could have used `'Country'`. The nice part of using the latter declaration, enclosed in quotes, is that you do not have to define your class before this class. So Country and Address can live in separate files and as long as both constants are available when it comes time to parse you are golden.

## Inheritance (it doesn't work!)

While mapping XML to objects you may arrive at a point where you have two or more very similar structures.

    class Article
      include HappyMapper
  
      has_one :title, String
      has_one :author, String
      has_one :published, Time
  
      has_one :entry, String
  
    end

    class Gallery
      include HappyMapper
  
      has_one :title, String
      has_one :author, String
      has_one :published, Time
  
      has_many :photos, String

    end

In this example there are definitely two similarities between our two pieces of content. So much so that you might be included to create an inheritance structure to save yourself some keystrokes.

    class Content
      include HappyMapper
  
      has_one :title, String
      has_one :author, String
      has_one :published, Time

    end

    class Article < Content
      include HappyMapper
      
      has_one :entry, String
    end
    
    class Gallery < Content
      include HappyMapper
      
      has_many :photos, String
    end
    
However, *this does not work*. And the reason is because each one of these element declarations are method calls that are defining elements on the class itself. So it is not passed down through inheritance.

You can however, use some module mixin power to save you those keystrokes and impress your friends.


    module Content
      def self.included(content)
        content.instance_eval do
    
          has_one :title, String
          has_one :author, String
          has_one :published, Time
      
        end
      end
      
      def published_time
        @published.strftime("%H:%M:%S")
      end
      
    end

    class Article
      include HappyMapper
      
      include Content
      has_one :entry, String
    end

    class Gallery
      include HappyMapper
      
      include Content
      has_many :photos, String
    end


Here, when we include `Content` in both of these classes the module method `#included` is called and our class is given as a parameter. So we take that opportunity to do some surgery and define our happymapper elements as well as any other methods that may rely on those instance variables that come along in the package.


## Subclasses
I ran into a case where I wanted to capture all the pictures that were directly under media, but not the ones contained within a gallery.

    <media>
      <gallery>
        <picture>
          <name>Burtie Sanchez</name>  
          <img>burtie01.png</img>
        </picture>
      </gallery>
      <picture>
        <name>Unsorted Photo</name>  
        <img>bestfriends.png</img>
      </picture>
    </media>
    
The following `Media` class is where I started:

    require 'happymapper'

    class Media
      include HappyMapper
  
      has_many :galleries, Gallery, :tag => 'gallery'
      has_many :pictures, Picture, :tag => 'picture'
    end

However when I parsed the media xml the number of pictures returned to me was 2, not 1.

    pictures = Media.parse(MEDIA_XML,:single => true).pictures
    pictures.length.should == 1   # => Failed Expectation

I was mistaken and that is because, by default the mappings are assigned XPATH './/' which is requiring all the elements no matter where they can be found. To override this you can specify an XPATH value for your defined elements.

    has_many :pictures, Picture, :tag => 'picture', :xpath => '/media'

`/media` states that we are only interested in pictures that can be found directly under the media element. So when we parse again we will have only our one element.


## Namespaces

Obviously your XML and these trivial examples are going to easy to map and parse because they lack the treacherous namespaces that befall most XML files.

Perhaps our `address` XML is really swarming with namespaces:

    <prefix:address location='home' xmlns:prefix="http://www.unicornland.com/prefix">
      <prefix:street>Milchstrasse</prefix:street>
      <prefix:street>Another Street</prefix:street>
      <prefix:housenumber>23</prefix:housenumber>
      <prefix:postcode>26131</prefix:postcode>
      <prefix:city>Oldenburg</prefix:city>
      <prefix:country code="de">Germany</prefix:country>
    </prefix:address>

Here again is our address example with a made up namespace called `prefix` that comes direct to use from unicornland, a very magical place indeed. Well we are going to have to do some work on our class definition and that simply adding this one liner to `Address`:

    namespace 'prefix'
    
Of course, if that is too easy for you, you can append a `:namespace => 'prefix` to every one of the elements that you defined. 

    has_many :street, String, :tag => 'street', :namespace => 'prefix'
    element :postcode, String, :tag => 'postcode', :namespace => 'prefix'
    element :housenumber, String, :tag => 'housenumber', :namespace => 'prefix'
    element :city, String, :tag => 'city', :namespace => 'prefix'
    element :country, Country, :tag => 'country', :namespace => 'prefix'
    
I definitely recommend the former, as it saves you a whole hell of lot of typing. However, there are times when appending a namespace to an element declaration is important and that is when it has a different namespace then `namespsace 'prefix'`.

Imagine that our `country` actually belonged to a completely different namespace.

    <prefix:address location='home' xmlns:prefix="http://www.unicornland.com/prefix"
    xmlns:different="http://www.trollcountry.com/different">
      <prefix:street>Milchstrasse</prefix:street>
      <prefix:street>Another Street</prefix:street>
      <prefix:housenumber>23</prefix:housenumber>
      <prefix:postcode>26131</prefix:postcode>
      <prefix:city>Oldenburg</prefix:city>
      <different:country code="de">Germany</different:country>
    </prefix:address>

Well we would need to specify that namespace:

    element :country, Country, :tag => 'country', :namespace => 'different'
    
With that we should be able to parse as we once did.

## Saving to XML

Saving a class to XML is as easy as calling `#to_xml`.  The end result will be the current state of your object represented as xml. Let's cover some details that are sometimes necessary and features present to make your life easier.


### :on_save

When you are saving data to xml it is often important to change or manipulate data to a particular format. For example, a time object:

    has_one :published_time, Time, :on_save => lambda {|time| time.strftime("%H:%M:%S") if time }
  
Here we add the options `:on_save` and specify a lambda which will be executed on the method call to `:published_time`.

### :state_when_nil

When an element contains a nil value, or perhaps the result of the :on_save lambda correctly results in a nil value you will be happy that the element will not appear in the resulting XML. However, there are time when you will want to see that element and that's when `:state_when_nil` is there for you.

    has_one :favorite_color, String, :state_when_nil => true
    
The resulting XML will include the 'favorite_color' element even if the favorite color has not been specified.

### :read_only

When an element, attribute, or text node is a value that you have no interest in
saving to XML, you can ensure that takes place by stating that it is `read only`.

    has_one :modified, Boolean, :read_only => true
    attribute :temporary, Boolean, :read_only => true
    
This is useful if perhaps the incoming XML is different than the out-going XML.

### namespaces

While parsing the XML only required you to simply specify the prefix of the namespace you wanted to parse, when you persist to xml you will need to define your namespaces so that they are correctly captured.

    class Address
      include HappyMapper
      
      register_namespace 'prefix', 'http://www.unicornland.com/prefix'
      register_namespace 'different', 'http://www.trollcountry.com/different'
      
      tag 'address'
      namespace 'prefix'
      
      has_many :street, String
      element :postcode, String
      element :housenumber, String
      element :city, String
      element :country, Country, :tag => 'country', :namespace => 'different'
    
    end