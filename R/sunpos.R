
    sunpos <- function(year, month, day, hour=12, min=0, sec=0,
                        lat, lon) {
    
        twopi <- 2 * pi
        deg2rad <- pi / 180
        
        # Get day of the year, e.g. Feb 1 = 32, Mar 1 = 61 on leap years
        month.days <- c(0,31,28,31,30,31,30,31,31,30,31,30)
        day <- day + cumsum(month.days)[month]
        leapdays <- year %% 4 == 0 & (year %% 400 == 0 | year %% 100 != 0) & 
            day >= 60 & !(month==2 & day==60)
        day[leapdays] <- day[leapdays] + 1
        
        # Get Julian date - 2400000
        hour <- hour + min / 60 + sec / 3600 # hour plus fraction
        delta <- year - 1949
        leap <- trunc(delta / 4) # former leapyears
        jd <- 32916.5 + delta * 365 + leap + day + hour / 24
        
        # The input to the Atronomer's almanach is the difference between
        # the Julian date and JD 2451545.0 (noon, 1 January 2000)
        time <- jd - 51545.
        
        # Ecliptic coordinates
        
        # Mean longitude
        mnlon <- 280.460 + .9856474 * time
        mnlon <- mnlon %% 360
        mnlon[mnlon < 0] <- mnlon[mnlon < 0] + 360
        
        # Mean anomaly
        mnanom <- 357.528 + .9856003 * time
        mnanom <- mnanom %% 360
        mnanom[mnanom < 0] <- mnanom[mnanom < 0] + 360
        mnanom <- mnanom * deg2rad
        
        # Ecliptic longitude and obliquity of ecliptic
        eclon <- mnlon + 1.915 * sin(mnanom) + 0.020 * sin(2 * mnanom)
        eclon <- eclon %% 360
        eclon[eclon < 0] <- eclon[eclon < 0] + 360
        oblqec <- 23.439 - 0.0000004 * time
        eclon <- eclon * deg2rad
        oblqec <- oblqec * deg2rad
        
        # Celestial coordinates
        # Right ascension and declination
        num <- cos(oblqec) * sin(eclon)
        den <- cos(eclon)
        ra <- atan(num / den)
        ra[den < 0] <- ra[den < 0] + pi
        ra[den >= 0 & num < 0] <- ra[den >= 0 & num < 0] + twopi
        dec <- asin(sin(oblqec) * sin(eclon))
        
        # Local coordinates
        # Greenwich mean sidereal time
        gmst <- 6.697375 + .0657098242 * time + hour
        gmst <- gmst %% 24
        gmst[gmst < 0] <- gmst[gmst < 0] + 24.
        
        # Local mean sidereal time
        lmst <- gmst + lon / 15.
        lmst <- lmst %% 24.
        lmst[lmst < 0] <- lmst[lmst < 0] + 24.
        lmst <- lmst * 15. * deg2rad
        
        # Hour angle
        ha <- lmst - ra
        ha[ha < -pi] <- ha[ha < -pi] + twopi
        ha[ha > pi] <- ha[ha > pi] - twopi
        
        # Latitude to radians
        lat <- lat * deg2rad
        
        # Azimuth and elevation
        el <- asin(sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(ha))
        az <- asin(-cos(dec) * sin(ha) / cos(el))
        
        # For logic and names, see Spencer, J.W. 1989. Solar Energy. 42(4):353
        cosAzPos <- (0 <= sin(dec) - sin(el) * sin(lat))
        sinAzNeg <- (sin(az) < 0)
        az[cosAzPos & sinAzNeg] <- az[cosAzPos & sinAzNeg] + twopi
        az[!cosAzPos] <- pi - az[!cosAzPos]
        
        el <- el / deg2rad
        az <- az / deg2rad
        lat <- lat / deg2rad
        
        return(list(elevation=el, azimuth=az))
    }