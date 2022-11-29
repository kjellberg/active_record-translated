active_record-translated
========

[![RuboCop](https://github.com/kjellberg/active_record-translated/actions/workflows/rubocop.yml/badge.svg)](https://github.com/kjellberg/active_record-translated/actions/workflows/rubocop.yml)
[![RSpec](https://github.com/kjellberg/active_record-translated/actions/workflows/rspec.yml/badge.svg)](https://github.com/kjellberg/active_record-translated/actions/workflows/rspec.yml)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)

This gem tackles localization of ActiveRecord models in Ruby on Rails by keeping records in different languages within the same database table. Translations are separated by a `locale`-column and linked together with an indexed `record_id`-column.

Since all database rows now are language-specific, this approach works best for models where **all or most of the attributes should be translatable**. Or else you may end up with a lot of duplicated data. For a visual example, check out examples further down this readme.

### Guidelines

These are the guidlines we should follow when developing this gem:

- Should work without any modifications to current application code.
- Should not decrease performance with multiple SQL queries.
- Should act like a normal record if no locale is set.
- Should accept an unlimited number of languages without decreased performance caused by this gem.
- Should not brake current specs/tests.
- Should not brake model validations
- All translations will have it's own record.
- Translations of the same object should have the same `record_id`
- A translation should know all other available translations with the same `record_id`
- Should work independently on what type (int/uuid..) of primary key the database table is using.

Installation
------------

Add the following line to Gemfile:

```ruby
gem "active_record-translated", github: 'kjellberg/active_record-translated'
```

and run `bundle install` from your terminal to install it.

Getting started
---------------

To generate the initializer and default configuration, run:

```console
rails generate translated:install
```

*This will create an initializer at `config/initializers/active_record-translated.rb`*

### Make a model translatable

To enable translation for a model, run:

```console
rails generate translated MODEL
```

*This will generate a database migration for the `locale` and `record_id` attributes and setup your model for translation.*

Examples
--------

The `posts` table below represents a translated `Post` model with the attributes `title` and `slug`. Note that `resource_id` and `locale` was created by this gem when you generated the migrations.

<table>
  <thead>
    <th>id</th>
    <th>resource_id</th>
    <th>locale</th>
    <th>title</th>
    <th>slug</th>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>42fb060d-2000-4a73-bb74-cfb5ca799e0d</td>
      <td>en</td>
      <td>Good morning!</td>
      <td>a-blog-post</td>
    </tr>
    <tr>
      <td>2</td>
      <td>42fb060d-2000-4a73-bb74-cfb5ca799e0d</td>
      <td>es</td>
      <td>Buenos días!</td>
      <td>una-publicacion-de-blog</td>
    </tr>
    <tr>
      <td>3</td>
      <td>160f6aee-ba2d-4c7e-a273-96b99468c8f9</td>
      <td>en</td>
      <td>Good night!</td>
      <td>another-blog-post</td>
    </tr>
    <tr>
      <td>4</td>
      <td>160f6aee-ba2d-4c7e-a273-96b99468c8f9</td>
      <td>es</td>
      <td>Buenas noches!</td>
      <td>otra-entrada</td>
    </tr>
  </tbody>
</table>

Your model may look something like this:

```ruby
# app/models/post.rb

class Post < ApplicationRecord
  # Enable translations for this model
  include ActiveRecord::Translated::Model
  
  # You can keep using validations the same way you did before installing this gem. The only
  # difference is that validations will be run on all translations separately.
  #
  # Examples:
  #  - Title must exist on each translation.
  #  - Every translation should have it's unique slug.
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
end
```

### Create a new record

The creation of a new record will autmatically generate a unique `record_id` and set the `locale` attribute to the current locale. The current locale is determined globally by `I18n.locale` and/or within the gem via `ActiveRecord::Translated.locale`, the latter with greater priority. The default locale if nothing is set is `:en`.

```ruby
before_action do
  I18n.locale = :en_US # fallback if "ActiveRecord::Translated.locale" is not set
  ActiveRecord::Translated.locale = :en_UK # has priority over "I18n.locale"
end

# POST /posts/create
def create
  @post = Post.create(title: "A post!", ...)

  @post.id # => 5
  @post.record_id # => 448ecc54-cc82-4c24-aed4-89fae5d38ec4 (auto-generated)
  @post.locale # => :en_UK
  ...
end
```

### Create a new record in a specific language

To create a post in a language other than the current locale, just pass a language code to the `locale` attribute.

```ruby
post = Post.create(title: "Una entrada de blog", ..., locale: :es)
post.locale # => :es
```

#### Using #with_locale

You can also wrap your code inside `ActiveRecord::Translated#with_locale`. This will temporary override the current locale within the block.

```ruby
post = ActiveRecord::Translated.with_locale(:es) do
  Post.create(title: "Una entrada de blog", ...)
end

post.locale # => :es
```

### Create a new translation of an existing record

To translate an already existing post, create a second post with a different `locale` and add it to the first post via `#translations`. This will make sure that our two translations are linked together with a shared `record_id`.

```ruby
# Create an english post
post = Post.create(title: "A post!", ...)

# Create a spanish translation
post_es = Post.create(title: "Una entrada de blog", ..., locale: :es)

# Associate the Spanish translation with the english post
post.translations << post_es

# Record ID should match:
post.record_id # => 448ecc54-cc82-4c24-aed4-89fae5d38ec4
post_es.record_id # => 448ecc54-cc82-4c24-aed4-89fae5d38ec4

# Locale should differ:
post.locale # => :en
post_es.locale # => :es
```

### Fetch a translated record

Your translated model will automatically scope query results by the current locale. For example, with `I18n.locale` set to `:sv`, your model will only return Swedish results. There's some different ways to fetch translations from the database using ActiveRecord's #find:

#### Find by primary key

This gem wont break the default #find method. So if you already now the ID, just fetch it with a normal #find:

```ruby
I18n.locale = :en # Ignored by #find when fetching a record by its primary key.

post = Post.find(5) # Spanish translation
post.locale #=> :es
```

#### Find by record_id

You can also find a translated record by using a record_id as the argument. This will look for a row that matches both the record_id and the current locale:

```ruby
I18n.locale = :es

post = Post.find("0e048f11-0ad9-48f1-b493-36e1f01d7994") 
post.locale #=> :es
```

#### Fetching collection of records

All query results are scoped by the current locale. Use `#unscoped_locale` to disable the locale scope.

```ruby

Post.create(title: "Foo bar", ..., locale: :es) # es
Post.create(title: "Foo bar", ..., locale: :es) # es
Post.create(title: "Foo bar", ..., locale: :pt) # pt

I18n.locale = :es
Post.count #=> :2

I18n.locale = :pt
Post.count #=> :1

# Returns all posts
Post.unscoped_locale.count #=> :3
```

License
-------

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

Contributing
------------

New contributors are very welcome and needed. This gem is an open-source, community project that anyone can contribute to. Reviewing and testing is highly valued and the most effective way you can contribute as a new contributor. It also will teach you much more about the code and process than opening pull requests.

Except for testing, there are several ways you can contribute to the betterment of the project:

- **Report an issue?** - If the issue isn’t reported, we can’t fix it. Please report any bugs, feature, and/or improvement requests on the [GitHub Issues tracker](https://github.com/kjellberg/active_record-translated/issues).
- **Submit patches** - Do you have a new feature or a fix you'd like to share? [Submit a pull request](https://github.com/kjellberg/active_record-translated/pulls)!
- **Write blog articles** - Are you using this gem? We'd love to hear how you're using it in your projects. Write a tutorial and post it on your blog!

### Development process

The `main` branch is regularly built and tested, but it is not guaranteed to be completely stable. Tags are created regularly from release branches to indicate new official, stable release versions of the libraries.

### Commit message guidelines

A good commit message should describe what changed and why. This project uses [semantic commit messages](https://www.conventionalcommits.org/en/v1.0.0/) to streamline the release process. Before a pull request can be merged, it must have a pull request title with a semantic prefix.

### Versioning

This application aims to adhere to [Semantic Versioning](http://semver.org/). Violations
of this scheme should be reported as bugs. Specifically, if a minor or patch
version is released that breaks backward compatibility, that version should be
immediately yanked and/or a new version should be immediately released that
restores compatibility. Breaking changes to the public API will only be
introduced with new major versions.
