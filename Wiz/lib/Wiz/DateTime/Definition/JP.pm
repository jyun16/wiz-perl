package Wiz::DateTime::Definition::JP;

use strict;
use warnings;

use base qw/Wiz::DateTime::Definition/;

use constant SPRING =>  { name => ['春分の日'], is_holiday => 1 };
use constant AUTUMN =>  { name => ['秋分の日'], is_holiday => 1 };

sub _rest_month_day {
    my ($self, $dd, $s, $dt) = @_;
    my $rest_month_day = $dd->{calendar}->{$s}->{month_day};
    my $rest_ymd       = $dd->{calendar}->{$s}->{ymd};
    my $rest_weekday   = $dd->{calendar}->{$s}->{weekday};
    my $date_data = {};
    my $ldt = $dt->clone->add(day => -1);
    my $tdt = $dt->clone->add(day => 1);

    my $date   = sprintf "%02d%02d", $dt->month, $dt->day;
    if (my $data = $rest_month_day->{$date}) {
        $self->_into_date_data($dt, $date_data, $data);
    } elsif (
             $ldt->day_of_week != 7 and
             ( $self->has_rest_ymd($rest_ymd, $ldt) or
               $self->has_rest_month_day($rest_ymd, $ldt) or
               $self->has_rest_weekday($rest_weekday, $ldt)
             ) and
             (
              ( $tdt->day_of_week != 6 and
                ($self->has_rest_ymd($rest_ymd, $tdt) or
                 $self->has_rest_month_day($rest_ymd, $tdt) or
                 $self->has_rest_weekday($rest_weekday, $tdt))
              ) or
              ( $tdt->day_of_week == 6 and
                $self->has_rest_ymd($rest_ymd, $tdt) or
                $self->has_rest_month_day($rest_ymd, $tdt)
                # Japanese moving holiday is always monday.
                # so not check has_rest_weekday
              )
             )
            ) {
        $data = {
                 is_holiday            => 1,
                 name                  => ['国民の休日'],
                };
        $self->_into_date_data($dt, $date_data, $data);
    } else {
        my $last_sun = $dt->clone;
        $last_sun->subtract(day => $last_sun->day_of_week) if $last_sun->day_of_week != 7;
        if (
            # When last sunday is holiday,
            # possible to be substitute holiday.
            $self->has_rest_month_day($rest_month_day, $last_sun) or
            $self->has_rest_ymd($rest_ymd, $last_sun)
           ) {
            my $ldt = $dt->clone->add(day => -1);
            if (
                # if last day is Sunday(7) and last day is holiday,
                # substitute holiday
                ($ldt->day_of_week == 7 and
                 ($self->has_rest_month_day($rest_month_day, $ldt) or
                  $self->has_rest_ymd($rest_ymd, $ldt)
                 )
                ) or
                # if year > 2007 and last day is holiday and last sunday is holiday,
                # substitute holiday
                ($dt->year > 2007 and
                 ($self->has_rest_month_day($rest_month_day, $ldt) or
                  $self->has_rest_ymd($rest_ymd, $ldt)
                 )
                )
               ) {
                # substitute holiday
                my $data = $self->has_rest_month_day($rest_month_day, $dt)
                    || $self->has_rest_ymd($rest_ymd, $dt);
                if (not $data) {
                    my $name;
                    if (ref $dd->{'substitute_holiday'}) {
                        $name = $dd->{'substitute_holiday'}->{name};
                        return unless $self->_check_in_range($dd->{'substitute_holiday'}, $dt);
                    } else {
                        $name = $dd->{'substitute_holiday'};
                    }
                    $data = {
                             is_holiday            => 1,
                             is_substitute_holiday => 1,
                             name                  => [$name],
                            };
                }
                $self->_into_date_data($dt, $date_data, $data);
            }
        }
    }
    return $date_data;
}

sub _date_definition {
    return
        {
         calendar =>
         {
          gregorian =>
          {
           month_day =>
           {
            '0101' => { name => ['元日'                    ], is_holiday => 1 },
            '0211' => { name => ['建国記念の日'            ], is_holiday => 1, range => [1967]},
            '0224' => { name => ['昭和天皇の大喪の礼'      ], is_holiday => 1, range => [1989, 1989]},
            '0115' => { name => ['成人の日'                ], is_holiday => 1, range => [0, 1999] },
            '0410' => { name => ['皇太子明仁親王の結婚の儀'], is_holiday => 1, range => [1959, 1959]},
            '0429' => [
                       { name => ['天皇誕生日'], is_holiday => 1, range => [0, 1988] },
                       { name => ['みどりの日'], is_holiday => 1, range => [1989, 2006] },
                       { name => ['昭和の日'  ], is_holiday => 1, range => [2007] },
                      ],
            '0503' => { name => ['憲法記念日'], is_holiday => 1 },
            '0504' => [
                       { name => ['国民の休日'], is_holiday => 1, range => [1988, 2006, [1992, 1997, 1998, 2003]] },
                       { name => ['みどりの日'], is_holiday => 1, range => [2007] },
                      ],
            '0505' => { name => ['こどもの日'], is_holiday => 1 },
            '0609' => { name => ['皇太子徳仁親王の結婚の儀'], is_holiday => 1, range => [1993, 1993] },
            '0720' => { name => ['海の日'      ], is_holiday => 1, range => [1996, 2002] },
            '0915' => { name => ['敬老の日'    ], is_holiday => 1, range => [1966, 2002] },
            '1010' => { name => ['体育の日'    ], is_holiday => 1, range => [1966, 2002] },
            '1103' => { name => ['文化の日'    ], is_holiday => 1 },
            '1112' => { name => ['即位礼正殿の儀'], is_holiday => 1, range => [1990, 1990] },
            '1123' => { name => ['勤労感謝の日'], is_holiday => 1 },
            '1223' => { name => ['天皇誕生日'  ], is_holiday => 1, range => [1989] },
           },
           weekday =>
           {
            '*-*-6'  => { name => ['土曜日'  ], is_holiday => 1 },
            '*-*-7'  => { name => ['日曜日'  ], is_holiday => 1 },
            '01-2-1' => { name => ['成人の日'], is_holiday => 1, range => [2003] },
            '07-3-1' => { name => ['海の日'  ], is_holiday => 1, range => [2003] },
            '09-3-1' => { name => ['敬老の日'], is_holiday => 1, range => [2003] },
            '10-2-1' => { name => ['体育の日'], is_holiday => 1, range => [2003] },
           },
           ymd =>
           {
            '1900-03-21' => SPRING,
            '1900-09-23' => AUTUMN,
            '1901-03-21' => SPRING,
            '1901-09-24' => AUTUMN,
            '1902-03-21' => SPRING,
            '1902-09-24' => AUTUMN,
            '1903-03-22' => SPRING,
            '1903-09-24' => AUTUMN,
            '1904-03-21' => SPRING,
            '1904-09-23' => AUTUMN,
            '1905-03-21' => SPRING,
            '1905-09-24' => AUTUMN,
            '1906-03-21' => SPRING,
            '1906-09-24' => AUTUMN,
            '1907-03-22' => SPRING,
            '1907-09-24' => AUTUMN,
            '1908-03-21' => SPRING,
            '1908-09-23' => AUTUMN,
            '1909-03-21' => SPRING,
            '1909-09-24' => AUTUMN,
            '1910-03-21' => SPRING,
            '1910-09-24' => AUTUMN,
            '1911-03-22' => SPRING,
            '1911-09-24' => AUTUMN,
            '1912-03-21' => SPRING,
            '1912-09-23' => AUTUMN,
            '1913-03-21' => SPRING,
            '1913-09-24' => AUTUMN,
            '1914-03-21' => SPRING,
            '1914-09-24' => AUTUMN,
            '1915-03-22' => SPRING,
            '1915-09-24' => AUTUMN,
            '1916-03-21' => SPRING,
            '1916-09-23' => AUTUMN,
            '1917-03-21' => SPRING,
            '1917-09-24' => AUTUMN,
            '1918-03-21' => SPRING,
            '1918-09-24' => AUTUMN,
            '1919-03-22' => SPRING,
            '1919-09-24' => AUTUMN,
            '1920-03-21' => SPRING,
            '1920-09-23' => AUTUMN,
            '1921-03-21' => SPRING,
            '1921-09-23' => AUTUMN,
            '1922-03-21' => SPRING,
            '1922-09-24' => AUTUMN,
            '1923-03-22' => SPRING,
            '1923-09-24' => AUTUMN,
            '1924-03-21' => SPRING,
            '1924-09-23' => AUTUMN,
            '1925-03-21' => SPRING,
            '1925-09-23' => AUTUMN,
            '1926-03-21' => SPRING,
            '1926-09-24' => AUTUMN,
            '1927-03-21' => SPRING,
            '1927-09-24' => AUTUMN,
            '1928-03-21' => SPRING,
            '1928-09-23' => AUTUMN,
            '1929-03-21' => SPRING,
            '1929-09-23' => AUTUMN,
            '1930-03-21' => SPRING,
            '1930-09-24' => AUTUMN,
            '1931-03-21' => SPRING,
            '1931-09-24' => AUTUMN,
            '1932-03-21' => SPRING,
            '1932-09-23' => AUTUMN,
            '1933-03-21' => SPRING,
            '1933-09-23' => AUTUMN,
            '1934-03-21' => SPRING,
            '1934-09-24' => AUTUMN,
            '1935-03-21' => SPRING,
            '1935-09-24' => AUTUMN,
            '1936-03-21' => SPRING,
            '1936-09-23' => AUTUMN,
            '1937-03-21' => SPRING,
            '1937-09-23' => AUTUMN,
            '1938-03-21' => SPRING,
            '1938-09-24' => AUTUMN,
            '1939-03-21' => SPRING,
            '1939-09-24' => AUTUMN,
            '1940-03-21' => SPRING,
            '1940-09-23' => AUTUMN,
            '1941-03-21' => SPRING,
            '1941-09-23' => AUTUMN,
            '1942-03-21' => SPRING,
            '1942-09-24' => AUTUMN,
            '1943-03-21' => SPRING,
            '1943-09-24' => AUTUMN,
            '1944-03-21' => SPRING,
            '1944-09-23' => AUTUMN,
            '1945-03-21' => SPRING,
            '1945-09-23' => AUTUMN,
            '1946-03-21' => SPRING,
            '1946-09-24' => AUTUMN,
            '1947-03-21' => SPRING,
            '1947-09-24' => AUTUMN,
            '1948-03-21' => SPRING,
            '1948-09-23' => AUTUMN,
            '1949-03-21' => SPRING,
            '1949-09-23' => AUTUMN,
            '1950-03-21' => SPRING,
            '1950-09-23' => AUTUMN,
            '1951-03-21' => SPRING,
            '1951-09-24' => AUTUMN,
            '1952-03-21' => SPRING,
            '1952-09-23' => AUTUMN,
            '1953-03-21' => SPRING,
            '1953-09-23' => AUTUMN,
            '1954-03-21' => SPRING,
            '1954-09-23' => AUTUMN,
            '1955-03-21' => SPRING,
            '1955-09-24' => AUTUMN,
            '1956-03-21' => SPRING,
            '1956-09-23' => AUTUMN,
            '1957-03-21' => SPRING,
            '1957-09-23' => AUTUMN,
            '1958-03-21' => SPRING,
            '1958-09-23' => AUTUMN,
            '1959-03-21' => SPRING,
            '1959-09-24' => AUTUMN,
            '1960-03-20' => SPRING,
            '1960-09-23' => AUTUMN,
            '1961-03-21' => SPRING,
            '1961-09-23' => AUTUMN,
            '1962-03-21' => SPRING,
            '1962-09-23' => AUTUMN,
            '1963-03-21' => SPRING,
            '1963-09-24' => AUTUMN,
            '1964-03-20' => SPRING,
            '1964-09-23' => AUTUMN,
            '1965-03-21' => SPRING,
            '1965-09-23' => AUTUMN,
            '1966-03-21' => SPRING,
            '1966-09-23' => AUTUMN,
            '1967-03-21' => SPRING,
            '1967-09-24' => AUTUMN,
            '1968-03-20' => SPRING,
            '1968-09-23' => AUTUMN,
            '1969-03-21' => SPRING,
            '1969-09-23' => AUTUMN,
            '1970-03-21' => SPRING,
            '1970-09-23' => AUTUMN,
            '1971-03-21' => SPRING,
            '1971-09-24' => AUTUMN,
            '1972-03-20' => SPRING,
            '1972-09-23' => AUTUMN,
            '1973-03-21' => SPRING,
            '1973-09-23' => AUTUMN,
            '1974-03-21' => SPRING,
            '1974-09-23' => AUTUMN,
            '1975-03-21' => SPRING,
            '1975-09-24' => AUTUMN,
            '1976-03-20' => SPRING,
            '1976-09-23' => AUTUMN,
            '1977-03-21' => SPRING,
            '1977-09-23' => AUTUMN,
            '1978-03-21' => SPRING,
            '1978-09-23' => AUTUMN,
            '1979-03-21' => SPRING,
            '1979-09-24' => AUTUMN,
            '1980-03-20' => SPRING,
            '1980-09-23' => AUTUMN,
            '1981-03-21' => SPRING,
            '1981-09-23' => AUTUMN,
            '1982-03-21' => SPRING,
            '1982-09-23' => AUTUMN,
            '1983-03-21' => SPRING,
            '1983-09-23' => AUTUMN,
            '1984-03-20' => SPRING,
            '1984-09-23' => AUTUMN,
            '1985-03-21' => SPRING,
            '1985-09-23' => AUTUMN,
            '1986-03-21' => SPRING,
            '1986-09-23' => AUTUMN,
            '1987-03-21' => SPRING,
            '1987-09-23' => AUTUMN,
            '1988-03-20' => SPRING,
            '1988-09-23' => AUTUMN,
            '1989-03-21' => SPRING,
            '1989-09-23' => AUTUMN,
            '1990-03-21' => SPRING,
            '1990-09-23' => AUTUMN,
            '1991-03-21' => SPRING,
            '1991-09-23' => AUTUMN,
            '1992-03-20' => SPRING,
            '1992-09-23' => AUTUMN,
            '1993-03-20' => SPRING,
            '1993-09-23' => AUTUMN,
            '1994-03-21' => SPRING,
            '1994-09-23' => AUTUMN,
            '1995-03-21' => SPRING,
            '1995-09-23' => AUTUMN,
            '1996-03-20' => SPRING,
            '1996-09-23' => AUTUMN,
            '1997-03-20' => SPRING,
            '1997-09-23' => AUTUMN,
            '1998-03-21' => SPRING,
            '1998-09-23' => AUTUMN,
            '1999-03-21' => SPRING,
            '1999-09-23' => AUTUMN,
            '2000-03-20' => SPRING,
            '2000-09-23' => AUTUMN,
            '2001-03-20' => SPRING,
            '2001-09-23' => AUTUMN,
            '2002-03-21' => SPRING,
            '2002-09-23' => AUTUMN,
            '2003-03-21' => SPRING,
            '2003-09-23' => AUTUMN,
            '2004-03-20' => SPRING,
            '2004-09-23' => AUTUMN,
            '2005-03-20' => SPRING,
            '2005-09-23' => AUTUMN,
            '2006-03-21' => SPRING,
            '2006-09-23' => AUTUMN,
            '2007-03-21' => SPRING,
            '2007-09-23' => AUTUMN,
            '2008-03-20' => SPRING,
            '2008-09-23' => AUTUMN,
            '2009-03-20' => SPRING,
            '2009-09-23' => AUTUMN,
            '2010-03-21' => SPRING,
            '2010-09-23' => AUTUMN,
            '2011-03-21' => SPRING,
            '2011-09-23' => AUTUMN,
            '2012-03-20' => SPRING,
            '2012-09-22' => AUTUMN,
            '2013-03-20' => SPRING,
            '2013-09-23' => AUTUMN,
            '2014-03-21' => SPRING,
            '2014-09-23' => AUTUMN,
            '2015-03-21' => SPRING,
            '2015-09-23' => AUTUMN,
            '2016-03-20' => SPRING,
            '2016-09-22' => AUTUMN,
            '2017-03-20' => SPRING,
            '2017-09-23' => AUTUMN,
            '2018-03-21' => SPRING,
            '2018-09-23' => AUTUMN,
            '2019-03-21' => SPRING,
            '2019-09-23' => AUTUMN,
            '2020-03-20' => SPRING,
            '2020-09-22' => AUTUMN,
            '2021-03-20' => SPRING,
            '2021-09-23' => AUTUMN,
            '2022-03-21' => SPRING,
            '2022-09-23' => AUTUMN,
            '2023-03-21' => SPRING,
            '2023-09-23' => AUTUMN,
            '2024-03-20' => SPRING,
            '2024-09-22' => AUTUMN,
            '2025-03-20' => SPRING,
            '2025-09-23' => AUTUMN,
            '2026-03-20' => SPRING,
            '2026-09-23' => AUTUMN,
            '2027-03-21' => SPRING,
            '2027-09-23' => AUTUMN,
            '2028-03-20' => SPRING,
            '2028-09-22' => AUTUMN,
            '2029-03-20' => SPRING,
            '2029-09-23' => AUTUMN,
            '2030-03-20' => SPRING,
            '2030-09-23' => AUTUMN,
            '2031-03-21' => SPRING,
            '2031-09-23' => AUTUMN,
            '2032-03-20' => SPRING,
            '2032-09-22' => AUTUMN,
            '2033-03-20' => SPRING,
            '2033-09-23' => AUTUMN,
            '2034-03-20' => SPRING,
            '2034-09-23' => AUTUMN,
            '2035-03-21' => SPRING,
            '2035-09-23' => AUTUMN,
            '2036-03-20' => SPRING,
            '2036-09-22' => AUTUMN,
            '2037-03-20' => SPRING,
            '2037-09-23' => AUTUMN,
            '2038-03-20' => SPRING,
            '2038-09-23' => AUTUMN,
            '2039-03-21' => SPRING,
            '2039-09-23' => AUTUMN,
            '2040-03-20' => SPRING,
            '2040-09-22' => AUTUMN,
            '2041-03-20' => SPRING,
            '2041-09-23' => AUTUMN,
            '2042-03-20' => SPRING,
            '2042-09-23' => AUTUMN,
            '2043-03-21' => SPRING,
            '2043-09-23' => AUTUMN,
            '2044-03-20' => SPRING,
            '2044-09-22' => AUTUMN,
            '2045-03-20' => SPRING,
            '2045-09-22' => AUTUMN,
            '2046-03-20' => SPRING,
            '2046-09-23' => AUTUMN,
            '2047-03-21' => SPRING,
            '2047-09-23' => AUTUMN,
            '2048-03-20' => SPRING,
            '2048-09-22' => AUTUMN,
            '2049-03-20' => SPRING,
            '2049-09-22' => AUTUMN,
            '2050-03-20' => SPRING,
            '2050-09-23' => AUTUMN,
            '2051-03-21' => SPRING,
            '2051-09-23' => AUTUMN,
            '2052-03-20' => SPRING,
            '2052-09-22' => AUTUMN,
            '2053-03-20' => SPRING,
            '2053-09-22' => AUTUMN,
            '2054-03-20' => SPRING,
            '2054-09-23' => AUTUMN,
            '2055-03-21' => SPRING,
            '2055-09-23' => AUTUMN,
            '2056-03-20' => SPRING,
            '2056-09-22' => AUTUMN,
            '2057-03-20' => SPRING,
            '2057-09-22' => AUTUMN,
            '2058-03-20' => SPRING,
            '2058-09-23' => AUTUMN,
            '2059-03-20' => SPRING,
            '2059-09-23' => AUTUMN,
            '2060-03-20' => SPRING,
            '2060-09-22' => AUTUMN,
            '2061-03-20' => SPRING,
            '2061-09-22' => AUTUMN,
            '2062-03-20' => SPRING,
            '2062-09-23' => AUTUMN,
            '2063-03-20' => SPRING,
            '2063-09-23' => AUTUMN,
            '2064-03-20' => SPRING,
            '2064-09-22' => AUTUMN,
            '2065-03-20' => SPRING,
            '2065-09-22' => AUTUMN,
            '2066-03-20' => SPRING,
            '2066-09-23' => AUTUMN,
            '2067-03-20' => SPRING,
            '2067-09-23' => AUTUMN,
            '2068-03-20' => SPRING,
            '2068-09-22' => AUTUMN,
            '2069-03-20' => SPRING,
            '2069-09-22' => AUTUMN,
            '2070-03-20' => SPRING,
            '2070-09-23' => AUTUMN,
            '2071-03-20' => SPRING,
            '2071-09-23' => AUTUMN,
            '2072-03-20' => SPRING,
            '2072-09-22' => AUTUMN,
            '2073-03-20' => SPRING,
            '2073-09-22' => AUTUMN,
            '2074-03-20' => SPRING,
            '2074-09-23' => AUTUMN,
            '2075-03-20' => SPRING,
            '2075-09-23' => AUTUMN,
            '2076-03-20' => SPRING,
            '2076-09-22' => AUTUMN,
            '2077-03-20' => SPRING,
            '2077-09-22' => AUTUMN,
            '2078-03-20' => SPRING,
            '2078-09-22' => AUTUMN,
            '2079-03-20' => SPRING,
            '2079-09-23' => AUTUMN,
            '2080-03-20' => SPRING,
            '2080-09-22' => AUTUMN,
            '2081-03-20' => SPRING,
            '2081-09-22' => AUTUMN,
            '2082-03-20' => SPRING,
            '2082-09-22' => AUTUMN,
            '2083-03-20' => SPRING,
            '2083-09-23' => AUTUMN,
            '2084-03-20' => SPRING,
            '2084-09-22' => AUTUMN,
            '2085-03-20' => SPRING,
            '2085-09-22' => AUTUMN,
            '2086-03-20' => SPRING,
            '2086-09-22' => AUTUMN,
            '2087-03-20' => SPRING,
            '2087-09-23' => AUTUMN,
            '2088-03-20' => SPRING,
            '2088-09-22' => AUTUMN,
            '2089-03-20' => SPRING,
            '2089-09-22' => AUTUMN,
            '2090-03-20' => SPRING,
            '2090-09-22' => AUTUMN,
            '2091-03-20' => SPRING,
            '2091-09-23' => AUTUMN,
            '2092-03-19' => SPRING,
            '2092-09-22' => AUTUMN,
            '2093-03-20' => SPRING,
            '2093-09-22' => AUTUMN,
            '2094-03-20' => SPRING,
            '2094-09-22' => AUTUMN,
            '2095-03-20' => SPRING,
            '2095-09-23' => AUTUMN,
            '2096-03-19' => SPRING,
            '2096-09-22' => AUTUMN,
            '2097-03-20' => SPRING,
            '2097-09-22' => AUTUMN,
            '2098-03-20' => SPRING,
            '2098-09-22' => AUTUMN,
            '2099-03-20' => SPRING,
            '2099-09-23' => AUTUMN,
            '2100-03-20' => SPRING,
            '2100-09-23' => AUTUMN,
            '2101-03-21' => SPRING,
            '2101-09-23' => AUTUMN,
            '2102-03-21' => SPRING,
            '2102-09-23' => AUTUMN,
            '2103-03-21' => SPRING,
            '2103-09-24' => AUTUMN,
            '2104-03-20' => SPRING,
            '2104-09-23' => AUTUMN,
            '2105-03-21' => SPRING,
            '2105-09-23' => AUTUMN,
            '2106-03-21' => SPRING,
            '2106-09-23' => AUTUMN,
            '2107-03-21' => SPRING,
            '2107-09-24' => AUTUMN,
            '2108-03-20' => SPRING,
            '2108-09-23' => AUTUMN,
            '2109-03-21' => SPRING,
            '2109-09-23' => AUTUMN,
            '2110-03-21' => SPRING,
            '2110-09-23' => AUTUMN,
            '2111-03-21' => SPRING,
            '2111-09-23' => AUTUMN,
            '2112-03-20' => SPRING,
            '2112-09-23' => AUTUMN,
            '2113-03-21' => SPRING,
            '2113-09-23' => AUTUMN,
            '2114-03-21' => SPRING,
            '2114-09-23' => AUTUMN,
            '2115-03-21' => SPRING,
            '2115-09-23' => AUTUMN,
            '2116-03-20' => SPRING,
            '2116-09-23' => AUTUMN,
            '2117-03-21' => SPRING,
            '2117-09-23' => AUTUMN,
            '2118-03-21' => SPRING,
            '2118-09-23' => AUTUMN,
            '2119-03-21' => SPRING,
            '2119-09-23' => AUTUMN,
            '2120-03-20' => SPRING,
            '2120-09-23' => AUTUMN,
            '2121-03-21' => SPRING,
            '2121-09-23' => AUTUMN,
            '2122-03-21' => SPRING,
            '2122-09-23' => AUTUMN,
            '2123-03-21' => SPRING,
            '2123-09-23' => AUTUMN,
            '2124-03-20' => SPRING,
            '2124-09-23' => AUTUMN,
            '2125-03-20' => SPRING,
            '2125-09-23' => AUTUMN,
            '2126-03-21' => SPRING,
            '2126-09-23' => AUTUMN,
            '2127-03-21' => SPRING,
            '2127-09-23' => AUTUMN,
            '2128-03-20' => SPRING,
            '2128-09-23' => AUTUMN,
            '2129-03-20' => SPRING,
            '2129-09-23' => AUTUMN,
            '2130-03-21' => SPRING,
            '2130-09-23' => AUTUMN,
            '2131-03-21' => SPRING,
            '2131-09-23' => AUTUMN,
            '2132-03-20' => SPRING,
            '2132-09-23' => AUTUMN,
            '2133-03-20' => SPRING,
            '2133-09-23' => AUTUMN,
            '2134-03-21' => SPRING,
            '2134-09-23' => AUTUMN,
            '2135-03-21' => SPRING,
            '2135-09-23' => AUTUMN,
            '2136-03-20' => SPRING,
            '2136-09-23' => AUTUMN,
            '2137-03-20' => SPRING,
            '2137-09-23' => AUTUMN,
            '2138-03-21' => SPRING,
            '2138-09-23' => AUTUMN,
            '2139-03-21' => SPRING,
            '2139-09-23' => AUTUMN,
            '2140-03-20' => SPRING,
            '2140-09-22' => AUTUMN,
            '2141-03-20' => SPRING,
            '2141-09-23' => AUTUMN,
            '2142-03-21' => SPRING,
            '2142-09-23' => AUTUMN,
            '2143-03-21' => SPRING,
            '2143-09-23' => AUTUMN,
            '2144-03-20' => SPRING,
            '2144-09-22' => AUTUMN,
            '2145-03-20' => SPRING,
            '2145-09-23' => AUTUMN,
            '2146-03-21' => SPRING,
            '2146-09-23' => AUTUMN,
            '2147-03-21' => SPRING,
            '2147-09-23' => AUTUMN,
            '2148-03-20' => SPRING,
            '2148-09-22' => AUTUMN,
            '2149-03-20' => SPRING,
            '2149-09-23' => AUTUMN,
            '2150-03-21' => SPRING,
            '2150-09-23' => AUTUMN,
           },
          },
         },
         substitute_holiday => {name => '振替休日', range => [1973]},
        };
}


=head1 NAME

Wiz::DateTime::Definition::JP - Date definition for Japanese Calendar

=head1 VERSION

version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

See L<Wiz::DateTime> module.

=head1 DESCRIPTION

In this definition, define saturday, sunday japanese holiday as holiday.

=head1 SEE ALSO

L<Wiz::DateTime>
L<Wiz::DateTime::Definition>

=head1 AUTHOR

Kato Atsushi, C<< <kato@adways.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 The Wiz Project. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE WIZ PROJECT ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL THE WIZ PROJECT OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OROTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are
those of the authors and should not be interpreted as representing official
policies, either expressed or implied, of the Wiz Project.

Additionally, the followings are recommended for the developers
to modify/improve/extend Wiz. Please send modified code/patch to mail list,
wiz-perl@googlegroups.com.
The source you sent will be merged into Wiz package.
We welcome anyone who cooperates with us in developing this software.

We'll invite you to this project's member.

=cut

1;
