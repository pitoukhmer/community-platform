package DDGC::Config;
# ABSTRACT: DDGC main configuration file 

use Moose;
use File::Path qw( make_path );
use File::Spec;
use File::ShareDir::ProjectDistDir;
use DDGC::Static;
use Path::Class;
use Catalyst::Utils;

has always_use_default => (
	is => 'ro',
	lazy => 1,
	default => sub { 0 },
);

sub has_conf {
	my ( $name, $env_key, $default ) = @_;
	my $default_ref = ref $default;
	has $name => (
		is => 'ro',
		lazy => 1,
		default => sub {
			my ( $self ) = @_;
			my $result;
			if ($self->always_use_default) {
				if ($default_ref eq 'CODE') {
					$result = $default->(@_);
				} else {
					$result = $default;
				}
			} else {
				if (defined $ENV{$env_key}) {
					$result = $ENV{$env_key};
				} else {
					if ($default_ref eq 'CODE') {
						$result = $default->(@_);
					} else {
						$result = $default;
					}
				}
			}
			return $result;
		},
	);
}

has_conf nid => DDGC_NID => 1;
has_conf pid => DDGC_PID => $$;

has_conf rootdir_path => DDGC_ROOTDIR => $ENV{HOME}.'/ddgc/';
has_conf ddgc_static_path => DDGC_STATIC => DDGC::Static->sharedir;
has_conf no_cache => DDGC_NOCACHE => 0;

sub rootdir {
	my ( $self ) = @_;
	my $dir = $self->rootdir_path;
	make_path($dir) if !-d $dir;
	return File::Spec->rel2abs( $dir );
}

has_conf web_base => DDGC_WEB_BASE => 'https://dukgo.com';

sub prosody_db_samplefile { File::Spec->rel2abs( File::Spec->catfile( dist_dir('DDGC'), 'ddgc.prosody.sqlite' ) ) }
sub duckpan_cdh_template { File::Spec->rel2abs( File::Spec->catfile( dist_dir('DDGC'), 'perldoc', 'duckpan.html' ) ) }
sub duckpan_cdh_assets {{
	'duckpan.css' => File::Spec->rel2abs( File::Spec->catfile( dist_dir('DDGC'), 'perldoc', 'duckpan.css' ) ),
	'duckpan.png' => File::Spec->rel2abs( File::Spec->catfile( dist_dir('DDGC'), 'perldoc', 'duckpan.png' ) ),
}}

has_conf prosody_db_driver => DDGC_PROSODY_DB_DRIVER => 'SQLite3';
has_conf prosody_db_database => DDGC_PROSODY_DB_DATABASE => sub {
	my ( $self ) = @_;
	return $self->rootdir().'/ddgc.prosody.sqlite';
};

has_conf prosody_db_username => DDGC_PROSODY_DB_USERNAME => undef;
has_conf prosody_db_password => DDGC_PROSODY_DB_PASSWORD => undef;
has_conf prosody_db_host => DDGC_PROSODY_DB_HOST => undef;
has_conf prosody_userhost => DDGC_PROSODY_USERHOST => 'test.domain';

sub is_live {
	my $self = shift;
	$self->prosody_userhost() eq 'dukgo.com' ? 1 : 0
}

sub is_view {
	my $self = shift;
	$self->prosody_userhost() eq 'view.dukgo.com' ? 1 : 0
}

has_conf prosody_admin_username => DDGC_PROSODY_ADMIN_USERNAME => 'testone';
has_conf prosody_admin_password => DDGC_PROSODY_ADMIN_PASSWORD => 'testpass';

has_conf mail_test => DDGC_MAIL_TEST => 0;
has_conf mail_test_log => DDGC_MAIL_TEST_LOG => '';
has_conf smtp_host => DDGC_SMTP_HOST => undef;
has_conf smtp_ssl => DDGC_SMTP_SSL => 0;
has_conf smtp_sasl_username => DDGC_SMTP_SASL_USERNAME => undef;
has_conf smtp_sasl_password => DDGC_SMTP_SASL_PASSWORD => undef;

has_conf templatedir => DDGC_TEMPLATEDIR => sub { dir( Catalyst::Utils::home('DDGC'), 'templates' )->resolve->absolute->stringify };

has_conf duckpan_url => DDGC_DUCKPAN_URL => 'http://duckpan.org/';
has_conf duckpan_locale_uploader => DDGC_DUCKPAN_LOCALE_UPLOADER => 'testone';
has_conf roboduck_aiml_botid => ROBODUCK_AIML_BOTID => 'ab83497d9e345b6b';
has_conf duckduckhack_url => DDGC_DUCKDUCKHACK_URL => 'http://duckduckhack.com/';

has_conf deleted_account => DDGC_DELETED_ACCOUNT => 'testone';

# DANGER: DEACTIVATES PASSWORD CHECK FOR ALL USERACCOUNTS!!!!!!!!!!!!!!!!!!!!!!
sub prosody_running { defined $ENV{'DDGC_PROSODY_RUNNING'} ? $ENV{'DDGC_PROSODY_RUNNING'} : 0 }
sub fallback_user { 'testtwo' }

sub prosody_connect_info {
	my ( $self ) = @_;
	my %params = (
		quote_char => '"',
		name_sep => '.',
		cursor_class => 'DBIx::Class::Cursor::Cached',
	);
	my $driver;
	if ($self->prosody_db_driver eq 'SQLite3') {
		$params{sqlite_unicode} = 1;
		$driver = 'SQLite';
	} elsif ($self->prosody_db_driver eq 'MySQL') {
		$params{mysql_enable_utf8} = 1;
		$driver = 'mysql';
	} elsif ($self->prosody_db_driver eq 'PostgreSQL') {
		$params{pg_enable_utf8} = 1;
		$driver = 'Pg';
	}
	my $dsn = 'dbi:'.$driver.':dbname='.$self->prosody_db_database.( $self->prosody_db_host() ? ';host='.$self->prosody_db_host : '' );
	return [
		$dsn,
		$self->prosody_db_username,
		$self->prosody_db_password,
		\%params,
	];
}

has_conf db_dsn => DDGC_DB_DSN => sub {
	my ( $self ) = @_;
	my $rootdir = $self->rootdir();
	warn "DANGER, using SQLite as driver for DDGC will be deprecated soon";
	return 'dbi:SQLite:'.$rootdir.'/ddgc.db.sqlite';
};

has_conf db_user => DDGC_DB_USER => '';
has_conf db_password => DDGC_DB_PASSWORD => '';

has db_params => (
	is => 'ro',
	lazy => 1,
	default => sub {
		my ( $self ) = @_;
		my %vars = (
			quote_char => '"',
			name_sep => '.',
			cursor_class => 'DBIx::Class::Cursor::Cached',
		);
		if ($self->db_dsn =~ m/:SQLite:/) {
			$vars{sqlite_unicode} = 1;
			$vars{on_connect_do} = 'PRAGMA SYNCHRONOUS = OFF';
		} elsif ($self->db_dsn =~ m/:Pg:/) {
			$vars{pg_enable_utf8} = 1;
		}
		return \%vars;
	},
);

sub duckpandir {
	my ( $self ) = @_;
	my $dir = defined $ENV{'DDGC_DUCKPANDIR'} ? $ENV{'DDGC_DUCKPANDIR'} : $self->rootdir().'/duckpan/';
	make_path($dir) if !-d $dir;
	return File::Spec->rel2abs( $dir );
}

sub filesdir {
	my ( $self ) = @_;
	my $dir = defined $ENV{'DDGC_FILESDIR'} ? $ENV{'DDGC_FILESDIR'} : $self->rootdir().'/files/';
	make_path($dir) if !-d $dir;
	return File::Spec->rel2abs( $dir );
}

sub screen_filesdir {
	my ( $self ) = @_;
	my $dir = defined $ENV{'DDGC_FILESDIR_SCREEN'} ? $ENV{'DDGC_FILESDIR_SCREEN'} : $self->filesdir().'/screens/';
	make_path($dir) if !-d $dir;
	return File::Spec->rel2abs( $dir );
}

sub cachedir {
	my ( $self ) = @_;
	my $dir = defined $ENV{'DDGC_CACHEDIR'} ? $ENV{'DDGC_CACHEDIR'} : $self->rootdir().'/cache/';
	make_path($dir) if !-d $dir;
	return File::Spec->rel2abs( $dir );
}

sub mediadir {
	my ( $self ) = @_;
	my $dir = defined $ENV{'DDGC_MEDIADIR'} ? $ENV{'DDGC_MEDIADIR'} : $self->rootdir().'/media/';
	make_path($dir) if !-d $dir;
	return File::Spec->rel2abs( $dir );
}

sub xslate_cachedir {
	my ( $self ) = @_;
	my $dir = defined $ENV{'DDGC_CACHEDIR_XSLATE'} ? $ENV{'DDGC_CACHEDIR_XSLATE'} : $self->cachedir().'/xslate/';
	make_path($dir) if !-d $dir;
	return File::Spec->rel2abs( $dir );
}

1;