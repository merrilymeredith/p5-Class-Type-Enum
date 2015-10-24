# Class::Type::Enum

This is just a little experiment that grew from liking Object::Enum, but
prefering something more akin to defining types, with traditional numeric
backing values and sortability.  If it seems like a good idea, it may grow into
a proper dist later, with a [DBIC][dbic] inflate helper bundled in.

[Object::Enum][objenum] works nicely for varchars with enum-like sets of
values, but all enums you get out of it are instances of Object::Enum.
Instead, this is a class builder which lets you treat that class as an enum
type.

Thanks to the ordinal values behind these enums, they can be sorted either by
ordinal (`<=>`) or by symbol (`cmp`).  This also allows for checks like
`$thing->status > $approved` in addition to the usual `$thing->status->is_foo`
checks.

_Unlike_ Object::Enum, objects are not mutable.

Also I liked `is_any` and `is_none` from [Enumeration][enumeration] and added
the same, as `any` and `none`.

## License

This software is licensed under the same terms as the Perl distribution itself.

[dbic]: https://metacpan.org/pod/DBIx::Class
[objenum]: https://metacpan.org/pod/Object::Enum
[enumeration]: https://metacpan.org/pod/Enumeration
