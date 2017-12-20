/**
*********************************************************************************
* Copyright Since 2014 CommandBox by Ortus Solutions, Corp
* www.coldbox.org | www.ortussolutions.com
********************************************************************************
* @author Brad Wood, Luis Majano, Denny Valliant
*
* I am the Git endpoint.  I get packages from a Git  URL.
*
* - git+ssh://git@github.com:user/repo.git#v1.0.27
* - git+https://login@github.com/user/repo.git
* - git+http://login@github.com/user/repo.git
* - git+https://login@github.com/user/repo.git
* - git://github.com/user/repom.git#v1.0.27
*
* If no <commit-ish> is specified, then master is used.
*
* Also supports this shortcut syntax for GitHub repos
* install mygithubuser/myproject
* install github:mygithubuser/myproject
*
*/
component accessors="true" implements="commandbox.system.endpoints.IEndpoint" singleton {

	// DI
	property name="consoleLogger"			inject="logbox:logger:console";
	property name="tempDir" 				inject="tempDir@constants";
	property name="artifactService" 		inject="ArtifactService";
	property name="folderEndpoint"			inject="commandbox.system.endpoints.Folder";
	property name="progressableDownloader" 	inject="ProgressableDownloader";
	property name="progressBar" 			inject="ProgressBar";
	property name="system" 					inject="system@constants";
	property name='wirebox' 				inject='wirebox';


	// Properties
	property name="namePrefixes" type="string";


	function init() {
		setNamePrefixes( 'localgit' );
		return this;
	}

	public string function resolvePackage( required string package, boolean verbose=false ) {
		

		var GitURL = replace( arguments.package, '//', '' );
		GitURL = getProtocol() & GitURL;
		var branch = 'master';
		if( GitURL contains '##' ) {
			branch = listLast( GitURL, '##' );
			GitURL = listFirst( GitURL, '##' );
			consoleLogger.debug( 'Using branch [#branch#]' );
		}
		//consoleLogger.debug( 'TempDir  [#tempDir#]' );
		consoleLogger.debug( 'Cloning Git URL [#GitURL#]' );


		// Wrap up system out in a PrintWriter and create a progress monitor to track our clone
		var printWriter = createObject( 'java', 'java.io.PrintWriter' ).init( system.out, true );
		//var progressMonitor = createObject( 'java', 'org.eclipse.jgit.lib.TextProgressMonitor' ).init( printWriter );

		// Temporary location to place the repo
		var localPath='#TempDir#/gitlocal_#randRange( 1, 1000 )#';
		//consoleLogger.debug( 'localPath [#localPath#]' );
directoryCreate(localPath);
sleep(10000);


		/*
		cfexecute(
			variable = "standardOutput",
			name = "git",
			arguments = " clone -b #branch# #GitURL# '#localPath#'",
			timeout = 100
   		 );
			*/

		var gitRunner = wirebox.getinstance( name='CommandDSL', initArguments={ name : 'run git clone -b #branch# #GitURL# "#localPath#"' } ).run( echo=true );

		return folderEndpoint.resolvePackage(  '#localPath#', arguments.verbose );
		


	}

	/**
	* Determines the name of a package based on its ID if there is no box.json
	*/
	public function getDefaultName( required string package ) {
		// Remove committ-ish
		var baseURL = listFirst( arguments.package, '##' );

		// Find last segment of URL (may or may not be a repo name)
		var repoName = listLast( baseURL, '/' );

		// Check for the "git" extension in URL
		if( listLast( repoName, '.' ) == 'git' ) {
			return listFirst( repoName, '.' );
		}
		return reReplaceNoCase( arguments.package, '[^a-zA-Z0-9]', '', 'all' );
	}

	private function getProtocol() {
		var prefix = getNamePrefixes();
		if( listFindNoCase( 'github,git+https,git', prefix ) ) {
			return "https://";
		} else if( prefix == 'git+http' ) {
			return "http://";
		} else if( prefix == 'git+ssh' ) {
			return "";
		}else if( prefix == 'localgit' ) {
			return "";
		}
		
		return prefix & '://';

	}

	public function getUpdate( required string package, required string version, boolean verbose=false ) {
		var result = {
			isOutdated = true,
			version = 'unknown'
		};

		return result;
	}

	// Default is no auth
	private function secureCloneCommand( required any cloneCommand ) {
		return cloneCommand;
	}

}
