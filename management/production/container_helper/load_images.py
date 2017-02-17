from wa_container import CBDockerEngine

if __name__ == "__main__":
    oDockerEngine = CBDockerEngine( "certs/", "cbs/", "tools/", "images/", "master1:5000/cromu/" )

    cbproxy_image_hash = oDockerEngine.GenCBProxyBaseImage( True)

    if ( cbproxy_image_hash is None ):
        print "Error -- failed to create cbproxy image!\n"

    # Tag it and push it
    push_result = oDockerEngine.PushImage( "master1:5000/cromu/cgc_cbproxy", "latest" )

    print "Push results:\n"
    print push_result
    
    pull_result = oDockerEngine.PullImage( "master1:5000/cromu/cgc_cbproxy", "latest" )

    print "Pull results:\n"
    print pull_result
'''
    # Build base images and push them to the private registry
    cbreplay_image_hash = oDockerEngine.GenCBReplayBaseImage( )

    if ( cbreplay_image_hash is None ):
        print "Error -- failed to create cbreplay image!\n"
    
    # Tag it and push it
    push_result = oDockerEngine.PushImage( "master1:5000/cromu/cgc_cbreplay", "latest" )

    print "Push results:\n"
    print push_result

    cbserver_image_hash = oDockerEngine.GenCBServerBaseImage( )

    if ( cbserver_image_hash is None ):
        print "Error -- failed to create cbserver image!\n"

    # Push it
    push_result = oDockerEngine.PushImage( "master1:5000/cromu/cgc_cbserver", "latest" )

    print "Push results:\n"
    print push_result


    # Pull images
    pull_result = oDockerEngine.PullImage( "master1:5000/cromu/cgc_cbreplay", "latest" )

    print "Pull results:\n"
    print pull_result

    pull_result = oDockerEngine.PullImage( "master1:5000/cromu/cgc_cbserver", "latest" )

    print "Pull results:\n"
    print pull_result
'''
