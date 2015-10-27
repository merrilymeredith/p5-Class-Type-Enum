package Class::Type::Enum;
# ABSTRACT: Build Enum-like classes

=head1 SYNOPSIS

  package Toast::Status {
    use Class::Type::Enum values => ['bread', 'toasting', 'toast', 'burnt'];
  }

  package Toast {
    use Moo;

    has status => (
      is     => 'rw',
      isa    => Toast::Status->get_test,
      coerce => Toast::Status->get_coerce,
    );
  }

  my @toast = map { Toast->new(status => $_) } qw( toast burnt bread bread toasting toast );

  my @trashcan = grep { $_->status->is_burnt } @toast;
  my @plate    = grep { $_->status->is_toast } @toast;

  my $ready_status   = Toast::Status->new('toast');
  my @eventual_toast = grep { $_->status < $ready_status } @toast;

  # or:

  @eventual_toast = grep { $_->status->none('toast', 'burnt') } @toast;

=head1 DESCRIPTION

Class::Type::Enum is a class builder for type-like classes to represent your
enumerated values.  In particular, it was built to scratch an itch with
L<DBIx::Class> value inflation.

I wouldn't consider the interface stable yet; I'd love feedback on this dist.

When C<use>ing Class::Type::Enum:

=begin :list

* Required:

=for :list
= values => [@symbols]
The list of symbolic values in your enum, in ascending order if relevant.

* Optional

=for :list
= init => $integer // 0
If provided, the ordinal values of your enum will begin with the init value.
= bits => $bool // !!0
If true, each ordinal will be an increasing power of two, rather than
increments.  That is, with this set, your enum's ordinal values will be 1, 2,
4, 8, 16, ... which can be handy for bit fields.

=end :list

=cut

use strict;
use warnings;

use Function::Parameters ':strict';
use List::Util ();
use Scalar::Util qw(blessed);
use Class::Method::Modifiers qw(install_modifier);

use namespace::clean;

use overload (
  '""'     => 'stringify',
  '0+'     => 'numify',
  fallback => 1,
);


=method $class->import(values => [], ...)

Sets up the consuming class as a subclass of Class::Type::Enum and installs
functions that are unique to the class.

=cut

fun import ($class, %params) {
  # import is inherited, but we don't want to do all this to everything that
  # uses a subclass of Class::Type::Enum.
  return unless $class eq __PACKAGE__;
  # If there's a use case for it, we can still allow extending CTE subclasses.

  my $target = caller;

  my %values;

  if (ref $params{values} eq 'ARRAY') {
    my $i = $params{init} // 0;

    %values = map {
      $_ => ($params{bits} ? 2**($i++) : $i++)
    } @{$params{values}};
  }
  elsif (ref $params{values} eq 'HASH') {
    %values = %{$params{values}};
  }
  else {
    die "Enum values must be provided either as an array or hash ref.";
  }

  ## the bits that are installed into the target class, plus @ISA
  {
    no strict 'refs';
    push @{"${target}::ISA"}, $class;
  }
  install_modifier $target, 'fresh', values_ord => sub { \%values };
  install_modifier $target, 'fresh', ord_values => sub { +{ reverse(%values) } };

  install_modifier $target, 'fresh', values => method {
    my $ord = $self->values_ord;
    [ sort { $ord->{$a} <=> $ord->{$b} } keys %values ];
  };

  for my $value (keys %values) {
    install_modifier $target, 'fresh', "is_$value" => method { $self->is($value) };
  }
}


=method $class->new($value)

Your basic constructor, expects only a value corresponding to a symbol in the
enum type.  Also works as an instance method for enums of the same class.

=cut

method new ($class: $value) {
  (blessed($class)// $class)->inflate_value($value);
}

=method $class->inflate_value($value)

Does the actual work of L<$class-E<gt>new($value)>, also used when inflating values for
L<DBIx::Class::InflateColumn::ClassTypeEnum>.

=cut

method inflate_value ($class: $value) {
  bless {
    ord => $class->values_ord->{$value}
        // die "Value [$value] is not valid for enum $class"
  }, $class;
}

=method $class->inflate($ord)

Used when inflating ordinal values for
L<DBIx::Class::InflateColumn::ClassTypeEnum> or if you need to work with
ordinals directly.

=cut

method inflate ($class: $ord) {
  die "Ordinal $ord is not valid for enum $class"
    if !exists $class->ord_values->{$ord};
  bless { ord => $ord }, $class;
}

=method $class->values_ord

Returns a hashref with symbols as keys and ordinals as values.

=method $class->ord_values

Returns a hashref with ordinals as keys and symbols as values.

=method $class->values

Returns an arrayref of valid symbolic values in order.

=method $class->get_test

Returns a function which either returns true if it's passed a valid value for
the enum, or throws an exception.

=cut

method get_test ($class:) {
  return fun ($value) {
    exists($class->values_ord->{$value})
      or die "Value [$value] is not valid for enum $class"
  }
}


=method $class->test($value)

A helper for directly using L<$class-E<gt>get_test>.

  Toast::Status->test('deleted')   # throws an exception

=cut

method test ($class: $value) {
  $class->get_test->($value)
}


=method $class->get_coerce

Returns a function which returns an enum if given an enum, or tries to create an enum from the given value using L<$class-E<gt>new($value)>.

TODO: test and coerce don't work with ordinals

=cut

method get_coerce ($class:) {
  return fun ($value) {
    eval { $value->isa($class) }
      ? $value
      : $class->new($value);
  }
}


=method $o->is($value)

Given a test value, returns true or false if the enum instance's value is equal
to the test value.

An exception is thrown if an invalid test value is given.

=method $o->is_$value

Shortcut for L<$o-E<gt>is($value)>

=cut

method is ($value) {
  $self->{ord} == ($self->values_ord->{$value} // die "Value [$value] is not valid for enum ". blessed($self))
}


=method $o->stringify

Returns the symbolic value.

=cut

method stringify {
  $self->ord_values->{$self->{ord}};
}

=method $o->numify

Returns the ordinal value.

=cut

method numify {
  $self->{ord}
}


=method $o->any(@cases)

True if C<$o-E<gt>is(..)> for any of the given cases.

=cut

method any (@cases) {
  List::Util::any { $self->is($_) } @cases;
}

=method $o->none(@cases)

True if C<$o-E<gt>is(..)> for none of the given cases.

=cut

method none (@cases) {
  List::Util::none { $self->is($_) } @cases;
}

=head1 SEE ALSO

=for :list
* L<Object::Enum>
* L<Class::Enum>
* L<Enumeration>

=cut


1;
