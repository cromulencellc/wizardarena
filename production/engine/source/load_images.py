from wa_container import CBDockerEngine
import settings

if __name__ == "__main__":
	oDockerEngine = CBDockerEngine( settings.DOCKER_HOST_ADDRESS, settings.DOCKER_CERT_PATH, settings.TOOL_FOLDER_PATH, settings.IMAGE_FOLDER_PATH, settings.DOCKER_REPO_NAME )

	oDockerEngine.LoadUbuntuImage()

	# Tag it and push it
	push_result = oDockerEngine.PushImage( "master1:5000/cromu/cgc_ubuntu", "latest" )

	print "Push results:\n"
	print push_result

	# Build base images and push them to the private registry
	cbreplay_image_hash = oDockerEngine.GenCBReplayBaseImage( )

	if ( cbreplay_image_hash is None ):
	    print "Error -- failed to create cbreplay image!\n"

	# Tag it and push it
	push_result = oDockerEngine.PushImage( "master1:5000/cromu/cgc_cbreplay", "latest" )

        print "cgc_cbreplay:: Push results:\n"
	print push_result

	cbserver_image_hash = oDockerEngine.GenCBServerBaseImage( )

	if ( cbserver_image_hash is None ):
	    print "Error -- failed to create cbserver image!\n"

	# Push it
	push_result = oDockerEngine.PushImage( "master1:5000/cromu/cgc_cbserver", "latest" )

        print "cgc_cbserver:: Push results:\n"
	print push_result

        # ================== CB-IDS ================== #
	cbids_image_hash = oDockerEngine.GenIDSBaseImage( )

	if ( cbids_image_hash is None ):
	    print "Error -- failed to create cbids image!\n"

	# Push it
	push_result = oDockerEngine.PushImage( "master1:5000/cromu/cgc_cbids", "latest" )

        print "cgc-cbids:: Push results:\n"
	print push_result

        # ================== POLL-GENERATOR =========== #
        pollgen_image_hash = oDockerEngine.GenPollGeneratorBaseImage( )

        if ( pollgen_image_hash is None ):
            print "Error - failed to create pollgen image!\n"

        # Push it
        push_result = oDockerEngine.PushImage( "master1:5000/cromu/cgc_pollgenerator", "latest" )

        print "cgc_pollgenerator:: Push results:\n"
        print push_result
	
        # Pull images
	pull_result = oDockerEngine.PullImage( "master1:5000/cromu/cgc_cbreplay", "latest" )
        print "cgc_cbreplay:: Pull results:\n"
	print pull_result

	pull_result = oDockerEngine.PullImage( "master1:5000/cromu/cgc_cbserver", "latest" )
        print "cgc_cbserver:: Pull results:\n"
	print pull_result
	
        pull_result = oDockerEngine.PullImage( "master1:5000/cromu/cgc_cbids", "latest" )
        print "cgc_cbids:: Pull results:\n"
	print pull_result

        pull_result = oDockerEngine.PullImage( "master1:5000/cromu/cgc_pollgenerator", "latest" )
        print "cgc_pollgenerator:: Pull results\n"
        print pull_result
