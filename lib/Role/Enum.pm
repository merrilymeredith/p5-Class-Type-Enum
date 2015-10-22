package Role::Enum;

use Moo::Role;
use MooX::Role::Parameterized qw(role apply);

use Function::Parameters ':strict';
use Scalar::Util qw(blessed);
use Class::Method::Modifiers qw(fresh);

use namespace::clean;

use overload (
  '""' => 'stringify',
  '0+' => 'numify',
  fallback => 1,
);

role(fun ($params) {
  my %params = %$params;
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

  fresh values_raw => sub { \%values };
  fresh raw_values => sub { +{ reverse(%values) } };

  fresh values => method {
    my $raw = $self->values_raw;
    [ sort { $raw->{$a} <=> $raw->{$b} } keys %values ];
  };


  for my $value (keys %values) {
    fresh "is_$value" => method { $self->is($value) };
  }
});


method import ($class: @params) {
  apply($class, {@params}, target => scalar(caller));
}

method new ($class: $value) {
  $class->inflate($value);
}

method inflate ($class: $value) {
  bless \(
    $class->values_raw->{$value}
    // die "Value [$value] is not valid for enum $class"
  ), $class;
}

method get_test ($class:) {
  return fun ($value) {
    exists($class->values_raw->{$value})
      or die "Value [$value] is not valid for enum $class"
  }
}

method test ($class: $value) {
  $class->get_test->($value)
}



method is ($value) {
  $$self == ($self->values_raw->{$value} // die "Value [$value] is not valid for enum ". blessed($self))
}

method stringify {
  $self->raw_values->{$$self};
}

method numify {
  $$self
}

1;
