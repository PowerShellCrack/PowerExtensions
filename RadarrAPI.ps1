

<#
    .LINK
    https://github.com/Radarr/Radarr/wiki/API:Movie
    


    .EXAMPLES
        rescan movies
        $movie_id = $env:radarr_movie_id
        $params = @{"name"="RescanMovie";"movieId"="$movie_id";} | ConvertTo-Json
        Invoke-WebRequest -Uri "http://localhost:7878/api/command?apikey=$radarrAPI" -Method POST -Body $params

        #find an movied in drone factory folder
        $params = @{"name"="DownloadedMoviesScan"} | ConvertTo-Json
        Invoke-WebRequest -Uri "http://localhost:7878/api/command?apikey=$radarrAPI" -Method POST -Body $params

        #find missing movies
        $params = @{"name"="missingMoviesSearch";"filterKey"="status";"filterValue"="released"} | ConvertTo-Json
        Invoke-WebRequest -Uri "http://localhost:7878/api/command?apikey=$radarrAPI" -Method POST -Body $params

        $MovieName = 
            $MovieRootPath = 'E:\Media\Movies\Superhero & Comics\Thor Collection\Thor - Ragnarok (2017)'

            $Body = @{ title="Thor: Ragnarok";
                        qualityProfileId="1";
                        year=2017;
                        tmdbid="284053";
                        titleslug="thor: ragnarok-284053";
                        monitored="true";
                        path=$MovieRootPath;
                        images=@( @{
                            covertype="poster";
                            url="https://image.tmdb.org/t/p/w174_and_h261_bestv2/avy7IR8UMlIIyE2BPCI4plW4Csc.jpg"
                        } )
                     }


            $BodyObj = ConvertTo-Json -InputObject $Body

            $BodyArray = ConvertFrom-Json -InputObject $BodyObj

            $iwrArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                            URI = "http://localhost:7878/api/movie"
                            Method = "POST"
                    }

                Invoke-WebRequest @iwrArgs -Body $BodyObj | Out-Null

        curl -H "Content-Type: application/json" -X POST -d '{"title":"Thor: Ragnarok","qualityProfileId":"6","tmdbid":"284053","titleslug":"thor: ragnarok-284053", "monitored":"true", "rootFolderPath":"H:/Video/Movies/", "images":[{"covertype":"poster","url":"https://image.tmdb.org/t/p/w174_and_h261_bestv2/avy7IR8UMlIIyE2BPCI4plW4Csc.jpg"}]}' http://192.168.1.111/radarr/api/movie?apikey=xxxxx
        curl -H "Content-Type: application/json" -X POST -d '{"title":"Proof","qualityProfileId":"4","apikey":"[MYAPIKEY]", "tmdbid":"14904","titleslug":"proof-14904", "monitored":"true", "rootFolderPath":"/Volume1/Movies/", "images":[{"covertype":"poster","url":"https://image.tmdb.org/t/p/w640/ghPbOsvg8WrJQBSThtNakBGuDi4.jpg"}]}' http://192.168.1.10:8310/api/movie
#>

Function Get-RadarrMovie{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]$Id,

        [Parameter(Mandatory=$false)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$true)]
        [string]$Api,

        [Parameter(Mandatory=$false)]
        [switch]$AsObject
    )
    Begin{
        [string]$URI = "${URL}:${Port}/api/movie"

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
    }
    Process {
        $RadarrGetArgs = @{Headers = @{"X-Api-Key" = $Api}
                    URI = "$URI/$Id"
                    Method = "Get"
        }
        #Write-Verbose $RadarrGetArgs.URI

        try {
            $request = Invoke-WebRequest @RadarrGetArgs -UseBasicParsing
            $MovieObj = $request.Content | ConvertFrom-Json
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
    End{
        If([boolean]$AsObject){
            return $MovieObj
        }
        Else{
            return $request
        }
    }
}

Function Get-AllRadarrMovies{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$true)]
        [string]$Api,

        [Parameter(Mandatory=$false)]
        [switch]$AsObject
    )
    Begin{
        [string]$URI = "${URL}:${Port}/api/movie"

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
    }
    Process {
        $RadarrGetArgs = @{Headers = @{"X-Api-Key" = $Api}
                    URI = $URI
                    Method = "Get"
                }

        Write-Verbose $RadarrGetArgs.URI

        Try{
            $Request = Invoke-WebRequest @RadarrGetArgs -UseBasicParsing
            $MovieObj = $Request.Content | ConvertFrom-Json
            #Write-Verbose ("Found {0}" -f $MovieObj.Count)
        }
        Catch{
            Write-Host "Unable to connect to Radarr, error $($_.Exception.ErrorMessage)"
        }
    }
    End {
        If([boolean]$AsObject){
            return $MovieObj
        }
        Else{
            return $Request
        }
    }
}


#Remove all movies
Function Remove-AllRadarrMovies{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$false)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false)]
        [string]$Port = '7878',
        
        [Parameter(Mandatory=$false)]
        [switch]$UnmonitoredOnly,

        [Parameter(Mandatory=$true)]
        [string]$Api
    )
    Begin{
        [string]$URI = "${URL}:${Port}/api/movie"

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        #Write-Verbose ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
    }
    Process {
        $removeMovies = @()
        If($UnmonitoredOnly){
            $i=1
            while ($i -le 500) {
                $iwrArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                            URI = "$URI/.$i"
                    }

                try {
                    $movie = Invoke-WebRequest @iwrArgs | Select-Object -ExpandProperty Content | ConvertFrom-Json
                    if ($movie.downloaded -eq $true -or $movie.monitored -eq $false) {
                        Write-Host "Adding $($movie.title) to list of movies to be removed." -ForegroundColor Red
                        $removeMovies += $movie
                    }
                    else {
                        Write-Host "$($movie.title) is monitored. Skipping." -ForegroundColor Gray
                    }
                }
                catch {
                    Write-Verbose "Empty ID#$i or bad request"
                }
                $i++

            }
        }
        Else{

        }
        Write-Host "Proceeding to remove $($removeMovies.count) movies!" -ForegroundColor Cyan

        foreach ($downloadedMovie in $removeMovies){
            $iwrArgs = @{Headers = @{"X-Api-Key" = $radarrAPIkey}
                    URI = "$URI/.$($downloadedMovie.id)"
                    Method = "Delete"
            }

            If(!$WhatIfPreference){
                Invoke-WebRequest @iwrArgs | Out-Null
                Write-Host "Removed $($downloadedMovie.title)!" -ForegroundColor Green
            }
        }
    }            
}

#Remove movie
Function Remove-RadarrMovie{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int32]$Id,

        [Parameter(Mandatory=$false)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$true)]
        [string]$Api,

        [Parameter(Mandatory=$false)]
        [switch]$Report
    )
    Begin{
        [string]$URI = "${URL}:${Port}/api/movie"

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        #Write-Verbose ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
    }
    Process {
        $ExistingMovie = Get-RadarrMovie -Id $Id -Api $Api -AsObject
        
        If($ExistingMovie){
            #Write-Host ("Found movie [{0}] in Radarr database..." -f $actualName) -ForegroundColor Gray
            If($VerbosePreference -eq "Continue"){
                Write-Host ("Removing Movie [{0}] from Radarr..." -f $ExistingMovie.Title) -ForegroundColor Yellow
                Write-Host ("   Title:") -ForegroundColor Gray -NoNewline
                    Write-Host (" {0}" -f $ExistingMovie.Title)
                Write-Host ("   Radarr ID:") -ForegroundColor Gray -NoNewline
                    Write-Host (" {0}" -f $ExistingMovie.id)
                Write-Host ("   Imdb:") -ForegroundColor Gray -NoNewline
                    Write-Host (" {0}" -f $ExistingMovie.imdbId)
                Write-Host ("   Path:") -ForegroundColor Gray -NoNewline
                    Write-Host (" {0}" -f $ExistingMovie.path)
            }


            $deleteMovieArgs = @{Headers = @{"X-Api-Key" = $Api}
                                URI = "$URI/$Id"
                                Method = "Delete"
            }

            try
            {
                If(!$WhatIfPreference){Invoke-WebRequest @deleteMovieArgs | Out-Null}
                $DeleteStatus = $true
            }
            catch {
                If($VerbosePreference -eq "Continue"){Write-Error -ErrorRecord $_}
                $DeleteStatus = $false
                #Break
            }
        
        }
        Else{
            Write-Host ("Movie with ID [{0}] does not exist in Radarr..." -f $Id) -ForegroundColor Yellow
            $DeleteStatus = $false
        }

    }
    End {
        If($Report -and $ExistingMovie){
            $MovieReport = @()
            $Movie = New-Object System.Object
            $Movie | Add-Member -Type NoteProperty -Name Id -Value $ExistingMovie.Id
            $Movie | Add-Member -Type NoteProperty -Name Title -Value $ExistingMovie.Title
            $Movie | Add-Member -Type NoteProperty -Name Year -Value $ExistingMovie.Year
            $Movie | Add-Member -Type NoteProperty -Name IMDB -Value $ExistingMovie.imdbID
            $Movie | Add-Member -Type NoteProperty -Name TMDB -Value $ExistingMovie.tmdbID
            $Movie | Add-Member -Type NoteProperty -Name TitleSlug -Value $ExistingMovie.titleslug
            $Movie | Add-Member -Type NoteProperty -Name FolderPath -Value $ExistingMovie.Path
            $Movie | Add-Member -Type NoteProperty -Name Deleted -Value $DeleteStatus
            $MovieReport += $Movie

            Return $MovieReport
        }
        ElseIf($Report -and !$ExistingMovie){
            $MovieReport = @()
            $Movie = New-Object System.Object
            $Movie | Add-Member -Type NoteProperty -Name Id -Value $ExistingMovie.Id
            $MovieReport += $Movie

            Return $MovieReport

        }
        Else{
            
            Return $DeleteStatus
        }

    }     
}

Function Add-RadarrMovie {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Year,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$imdbID,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]$tmdbID,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Poster')]
        [string]$PosterImage,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$true)]
        [string]$Api,

        [Parameter(Mandatory=$false)]
        [switch]$SearchAfterImport,

        [Parameter(Mandatory=$false)]
        [switch]$Report
    )
    Begin{
        [string]$URI = "${URL}:${Port}/api/movie"

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        #Write-Verbose ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
    }
    Process {
        If($VerbosePreference -eq "Continue"){Write-Host ("Processing details for movie title [{0}]..." -f $Title)}
        [string]$actualName = $Title
        [string]$sortName = ($Title).ToLower()
        $Regex = "[^{\p{L}\p{Nd}\'}]+"
        [string]$cleanName = (($Title) -replace $Regex,"").Trim().ToLower()
        [string]$ActualYear = $Year
        [string]$imdbID = $imdbID
        #[string]$imdbID = ($imdbID).substring(2,($imdbID).length-2)
        [int32]$tmdbID = $tmdbID
        [string]$Image = $PosterImage
        [string]$simpleTitle = (($Title).replace("'","") -replace $Regex,"-").Trim().ToLower()
        [string]$titleSlug = $simpleTitle + "-" + $tmdbID
    
        #Write-Host ("Adding movie [{0}] to Radarr database..." -f $actualName) -ForegroundColor Gray
        If($VerbosePreference -eq "Continue"){
            Write-Host ("   Title:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $actualName)
            Write-Host ("   Path:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $Path)
            Write-Host ("   Imdb:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $imdbID)
            Write-Host ("   Tmdb:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $tmdbID)
            Write-Host ("   Slug:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $titleSlug)
            Write-Host ("   Year:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $ActualYear)
            Write-Host ("   Poster:") -ForegroundColor Gray -NoNewline
                Write-Host (" {0}" -f $Image)
        }

        $Body = @{ title=$actualName;
            sortTitle=$sortName;
            cleanTitle=$cleanName;
            qualityProfileId="1";
            year=$ActualYear;
            tmdbid=$tmdbID;
            imdbid=$imdbID;
            titleslug=$titleSlug;
            monitored="true";
            path=$Path;
            addOptions=@{
                searchForMovie=[boolean]$SearchAfterImport
            };
            images=@( @{
                covertype="poster";
                url=$Image
            } );
        }

        $BodyObj = ConvertTo-Json -InputObject $Body #| % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
        #$BodyArray = ConvertFrom-Json -InputObject $BodyObj

        $RadarrPostArgs = @{Headers = @{"X-Api-Key" = $Api}
                        URI = $URI
                        Method = "Post"
                }
        try
        {
            If(!$WhatIfPreference){Invoke-WebRequest @RadarrPostArgs -Body $BodyObj | Out-Null}
            If($VerbosePreference -eq "Continue"){write-host "Invoke API using JSON: $BodyObj"}
            $ImportStatus = $true
            
        }
        catch {
            If($VerbosePreference -eq "Continue"){Write-Error -ErrorRecord $_}
            $ImportStatus = $false
            #Break
        }
    }
    End {
        If(!$Report){
            Return $ImportStatus
        }
        Else{
            $MovieReport = @()
            $Movie = New-Object System.Object
            $Movie | Add-Member -Type NoteProperty -Name Title -Value $actualName
            $Movie | Add-Member -Type NoteProperty -Name Year -Value $ActualYear
            $Movie | Add-Member -Type NoteProperty -Name IMDB -Value $imdbID
            $Movie | Add-Member -Type NoteProperty -Name TMDB -Value $tmdbID
            $Movie | Add-Member -Type NoteProperty -Name TitleSlug -Value $titleslug
            $Movie | Add-Member -Type NoteProperty -Name FolderPath -Value $Path
            $Movie | Add-Member -Type NoteProperty -Name RadarrUrl -Value ('http://' + $URL + ':' + $Port + '/movie/' + $titleSlug)
            $Movie | Add-Member -Type NoteProperty -Name Imported -Value $ImportStatus
            $MovieReport += $Movie

            Return $MovieReport

        }

    }
}

Function Update-RadarrMoviePath {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int32]$Id,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$FolderName,
        
        [Parameter(Mandatory=$true)]
        [string]$ActualPath,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Path')]
        [string]$RadarrPath,
        
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$TitleSlug,

        [Parameter(Mandatory=$false)]
        [string]$URL = 'http://localhost',
        
        [Parameter(Mandatory=$false)]
        [string]$Port = '7878',

        [Parameter(Mandatory=$true)]
        [string]$Api,

        [Parameter(Mandatory=$false)]
        [switch]$Report
    )
    Begin{
        [string]$URI = "${URL}:${Port}/api/movie"

        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
        #Write-Verbose ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
    }
    Process {
        #Write-Host ("Adding movie [{0}] to Radarr database..." -f $actualName) -ForegroundColor Gray
        If($VerbosePreference -eq "Continue"){
            Write-Host ("Movie [{0}] path is incorrect; updating Radarr's path..." -f $Title) -ForegroundColor Yellow
            Write-Host ("   Actual Path:") -ForegroundColor Gray -NoNewline
                 Write-Host (" {0}" -f $ActualPath)
            Write-Host ("   Radarr Path:") -ForegroundColor Gray -NoNewline
                 Write-Host (" {0}" -f $RadarrPath) -ForegroundColor Gray
        }

        #Grab current movie in Radarr
        $ExistingMovie = Get-RadarrMovie -Id $Id -Api $Api -AsObject
            
        #update PSObject values
        $ExistingMovie.folderName = $ActualPath
        $ExistingMovie.path = $ActualPath
        $ExistingMovie.PSObject.Properties.Remove('movieFile')  
        
        #convert PSObject back into JSON format
        $BodyObj = $ExistingMovie | ConvertTo-Json #| % { [System.Text.RegularExpressions.Regex]::Unescape($_) }

        $RadarrPutMovieID = @{Headers = @{"X-Api-Key" = $Api}
                    URI = $URI + "/" + $Id
                    Method = "Put"
                }  
        try
        {
            If($VerbosePreference -eq "Continue"){write-host ("Invoking [{0}] using JSON: {1}" -f ($URI + "/" + $Id),$BodyObj)}
            If(!$WhatIfPreference){Invoke-WebRequest @RadarrPutMovieID -Body $BodyObj | Out-Null}
            $UpdateStatus = $true
            
        }
        catch {
            If($VerbosePreference -eq "Continue"){Write-Error -ErrorRecord $_}
            $UpdateStatus = $false
            #Break
        }
    }
    End {
        If(!$Report){
            Return $UpdateStatus
        }
        Else{
            $MovieReport = @()
            $Movie = New-Object System.Object
            $Movie | Add-Member -Type NoteProperty -Name ID -Value $Id
            $Movie | Add-Member -Type NoteProperty -Name Title -Value $Title
            $Movie | Add-Member -Type NoteProperty -Name RadarrPath -Value $RadarrPath
            $Movie | Add-Member -Type NoteProperty -Name ActualPath -Value $ActualPath
            $Movie | Add-Member -Type NoteProperty -Name Updated -Value $UpdateStatus 
            $MovieReport += $Movie

            Return $MovieReport

        }
    }
}
