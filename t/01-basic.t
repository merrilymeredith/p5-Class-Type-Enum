use Test::More;

package Critter {
  use Class::Type::Enum values => [qw( mouse rabbit dog cat )];
}

package Vehicle {
  # Make sure it works more than once
  use Class::Type::Enum values => [qw(bike car bus train plane)];
}

# Just another compile check
use DBIx::Class::InflateColumn::ClassTypeEnum;


my $cat = new_ok( 'Critter', ['cat'] );

isa_ok( $cat, 'Class::Type::Enum' );

can_ok( $cat, qw( is is_mouse is_cat is_dog ) );

# use Devel::Dwarn;
# Dwarn {
#   cat => $cat,
#   values => $cat->raw_values,
# };
#
# Dwarn \%{Critter::};

ok( $cat->is('cat'), 'cat is a cat.');
ok( $cat->is_cat, 'cat is a cat!' );
ok( !$cat->is_dog, 'this aint no dog.' );

is( "$cat", 'cat', "stringified the cat, yeowch!" );
ok( $cat != 1, "are cats even numifiable?" );

ok( $cat == Critter->new('cat'), 'all cats are equal' );
ok( $cat == Critter->new("$cat"), 'no matter where they come from' );

ok( $cat > Critter->new('dog'), '...and more equal than dogs' );
ok( Critter->new('mouse') < $cat, 'these fierce predators' );

# Dwarn [ sort {$a <=> $b} map { Critter->new($_) } @{Critter->values} ];

ok( $cat->any(qw(rabbit cat)), 'others could be tolerated' );
ok( $cat->none(qw(dog mouse)), 'but we must keep standards' );

subtest 'test function for type checks?' => sub {
  ok( my $test = Critter->get_test, 'got a test function' );

  ok( $test->('rabbit'), 'rabbit ok' );
  ok( $test->($cat), 'cat ok' );

  ok( !defined eval { Critter->test('snake') }, 'no snakes' );
};

done_testing;

