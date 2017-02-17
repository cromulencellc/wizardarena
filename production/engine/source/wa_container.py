#!/usr/bin/env python

import docker
from io import BytesIO
from StringIO import StringIO
import tarfile
import binascii
import parse
import time
import logging

# Get a logger for the engine
logger = logging.getLogger('WAEngine')

class ContainerHelper:
	@staticmethod
	def GetHashFromResults( response ):
		response = "".join(response)

		for line in response.split('\n'):
			find_index = line.find( "Successfully built " )

			if ( find_index > -1 ):
				find_index_end = line[find_index:].find( "\\n\"}" )

				if ( find_index_end == -1 ):
					return None

				return line[find_index+19:find_index+find_index_end]

		return None

class CBDockerEngine:
	def __init__(self, docker_host, cert_path, tool_folder_path, image_folder_path, repo_name ):
                tls_config = docker.tls.TLSConfig( client_cert=(cert_path+'/client.pem', cert_path+'/client-key.pem'), verify=cert_path+'/ca.pem' )

                self.cli = docker.Client( base_url=("https://%s"%docker_host), tls=tls_config )

		# Save path to folder containing tools (cb-server, cb-replay, etc.)
		self.tool_folder_path = tool_folder_path

                # Path to image files
                self.image_folder_path = image_folder_path

                # Remember repository name
                self.repo_name = repo_name

        def GetDockerInfo(self):
                return self.cli.info()

        ''' Deprecated
        def LoadBaseImages( self ):
                images_to_load = [ { "Name" : "cgc_ubuntu", "File" : "cgc_ubuntu.tar" },
                                   { "Name" : "cgc_cbserver", "File" : "cgc_cbserver.tar" },
                                   { "Name" : "cgc_cbreplay", "File" : "cgc_cbreplay.tar" }
                                 ]

                for item in images_to_load:
                    load_result = self.DockerLoadImage( item["Name"], self.image_folder_path + item["File"] )

                    if ( load_result == None ):
                        print "Failed to load image: %s (File: %s)\n" % (item["Name"], item["File"])

                print "Images loaded"

        def DockerLoadImage( self, image_name, image_file ):

            image_data = open(image_file,"r").read()

            load_result = self.cli.load_image( data=image_data )

            return load_result
        '''

	def GetContainerList( self, name_filter="", show_all=False ):
		if ( len(name_filter) > 0 ):
			filter_list = { "name" : name_filter };
		else:
			filter_list = None

		if ( filter_list ):
			return self.cli.containers( all=show_all, filters=filter_list )
		else:
			return self.cli.containers( all=show_all )

	def GetContainerInfoByID( self, container_id ):
		container_info = self.cli.containers( filters={ 'id' : container_id } )

		if ( container_info == None ):
			return None
		else:
			return container_info[0]

	def GetContainerIDFromContainerListByName( self, container_list, match_name ):
		if ( container_list == None ):
			return None

		container_id_list = list()
		for item in container_list:
			for names in item['Names']:
				if ( names.rfind( '/' ) >= 0 ):
					name_check = names[names.rfind('/')+1:]
					if ( name_check == match_name ):
						container_id_list.append( item['Id'] )
						break
				else:
					if ( names == match_name ):
						container_id_list.append( item['Id'] )
						break

		return container_id_list

	def KillContainerByID( self, container_id ):
		if ( container_id == None ):
			return False

		kill_result = self.cli.kill( container=container_id )

		return kill_result
		
		
	def LoadImageFromFile( self, file_path, image_name ):
		# Load an image from a file	
		try:
			image_file_data = open(file_path, "rb").read()
		except IOError, e:
			print "File not found (%s)!" % (file_path)
			return None

		#print "Image file loaded size=%d\n" % len(image_file_data)
		load_results = self.cli.import_image_from_data( data=image_file_data, repository=image_name )

		return load_results 

        def CheckImageExists( self, image_repo_name, image_tag="latest" ):
		image_search = self.cli.images( )

                image_exists = False
		if ( image_search == None ):
                    return False

                image_search_name = ("%s:%s" % (image_repo_name,image_tag))

                #print "Searching for: %s\n" % image_search_name

		for item in image_search:
                    #print "========== IMAGE ========\n"
                    for repo_tag_name in item["RepoTags"]:
                        #print "Repo Tag Name: %s\n" % repo_tag_name
                        if ( repo_tag_name.encode("utf8") == image_search_name ):
			    image_exists = True
			    break

                return image_exists

	def LoadUbuntuImage( self ):
		# First check for 32bit/ubuntu:14.04
		if ( self.CheckImageExists( self.repo_name+"cgc_ubuntu" ) == False ):	
			print "Ubuntu image not found! reloading... "

                        load_results = self.LoadImageFromFile( "cgc_base_ubuntu.tz", self.repo_name+"cgc_ubuntu:latest" )

                        print load_results
		else:
			print "Ubuntu image not loaded (already exists)!"

        def GenCBPythonImage( self, force_reload = False ):
                self.LoadUbuntuImage()

                if ( force_reload == False ):
                    if ( self.CheckImageExists( self.repo_name+"cgc_pythonbase" ) == False ):
                        print "Reload cgc_pythonbase, as it does not exist!\n"
                    else:
                        print "Not loading cgc_pythonbase, as it already exists!\n"

                else:
                    print "Reload cgc_pythonbase, force reloading!\n"

                dockerfile = '''# CROMU Python Base Container
FROM '''+self.repo_name+'''cgc_ubuntu:latest
RUN apt-get install -y python
'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, forcerm=True, nocache=True, tag=self.repo_name+"cgc_pythonbase" )]

		print "cgc_pythonbase build response: "
		print response
		
                container_hash = ContainerHelper.GetHashFromResults( response )

		print "cgc_pythonbase container hash is: %s\n" % container_hash		

        def GenIDSBaseImage( self, force_reload = False ):
                self.LoadUbuntuImage()

                if ( force_reload == False ):
		    if ( self.CheckImageExists( self.repo_name+"cgc_cbids" ) == False ):	
		        print "Reloading cgc_cbids, as it does not exist!\n"
                    else:
			print "Not loading cgc_cbids as it already exists!\n"
                        return
                else:
                    print "Reload cgc_cbids, force reloading!\n"

		dockerfile = '''# CB IDS Container
FROM '''+self.repo_name+'''cgc_ubuntu:latest
ADD ''' + self.tool_folder_path + '''/cb-ids /usr/bin/
ADD ''' + self.tool_folder_path + '''/run-cb-ids /usr/bin/'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/cb-ids' )
		docker_tarfile.add( self.tool_folder_path + '/run-cb-ids' )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, forcerm=True, nocache=True, tag=self.repo_name+"cgc_cbids" )]

		print "cgc_cbids build response: "
		print response
                
		container_hash = ContainerHelper.GetHashFromResults( response )

		print "cgc_cbids container hash is: %s\n" % container_hash		

                # Commit image
                push_results = self.cli.push( self.repo_name+"cgc_cbids" )
                print "Push results: "
                print push_results

                return container_hash
		

	def GenCBReplayBaseImage( self, force_reload = False ):
                # Check for base python image 
                if ( self.CheckImageExists( self.repo_name+"cgc_pythonbase" ) == False ):
                    print "cgc_pythonbase not found -- generating!\n"

                    # Rebuild
                    self.GenCBPythonImage( True )

                if ( force_reload == False ):
		    if ( self.CheckImageExists( self.repo_name+"cgc_cbreplay" ) == False ):	
		        print "Reloading cgc_cbreplay, as it does not exist!\n"
                    else:
			print "Not loading cgc_cbreplay as it already exists!\n"
                        return
                else:
                    print "Reload cgc_cbreplay, force reloading!\n"

		dockerfile = '''# CB Replay Base Container
FROM '''+self.repo_name+'''cgc_pythonbase:latest
ADD ''' + self.tool_folder_path + '''/cb_replay.py /usr/lib/python2.7/
ADD ''' + self.tool_folder_path + '''/cb_replay_pov.py /usr/lib/python2.7/
ADD ''' + self.tool_folder_path + '''/prf.py /usr/lib/python2.7/
ADD ''' + self.tool_folder_path + '''/cb-master-replay /usr/bin/
ADD ''' + self.tool_folder_path + '''/run-cb-master-replay /usr/bin/
'''

#ADD ''' + self.tool_folder_path + '''/run-cb-replay /usr/bin/
		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/cb_replay.py' )
		docker_tarfile.add( self.tool_folder_path + '/cb_replay_pov.py' )
                docker_tarfile.add( self.tool_folder_path + '/prf.py' )
                docker_tarfile.add( self.tool_folder_path + '/cb-master-replay' )
		docker_tarfile.add( self.tool_folder_path + '/run-cb-master-replay' )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, forcerm=True, nocache=True, tag=self.repo_name+"cgc_cbreplay" )]

		print "cgc_cbreplay build response: "
		print response

		container_hash = ContainerHelper.GetHashFromResults( response )

		print "cgc_cbreplay container hash is: %s\n" % container_hash		

                return container_hash
		
	def GenCBServerBaseImage( self, force_reload = False ):
		self.LoadUbuntuImage()

                if ( force_reload == False ):
		    if ( self.CheckImageExists( self.repo_name+"cgc_cbserver" ) == False ):	
		        print "Reloading cgc_cbserver, as it does not exist!\n"
                    else:
			print "Not loading cgc_cbserver as it already exists!\n"
                        return

                else:
                    print "Reload cgc_cbserver, force reloading!\n"
		
                dockerfile = '''# CB Server Base Container
FROM '''+self.repo_name+'''cgc_ubuntu:latest
ADD ''' + self.tool_folder_path + '''cb-server /usr/bin/
ADD ''' + self.tool_folder_path + '''run-cb-server /usr/bin/
'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/cb-server' )
                docker_tarfile.add( self.tool_folder_path + '/run-cb-server' )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, forcerm=True, nocache=True, tag=self.repo_name+"cgc_cbserver" )]

		print "cgc_cbserver build response: "
		print response

		container_hash = ContainerHelper.GetHashFromResults( response )

		print "cgc_cbserver container hash is: %s\n" % container_hash		

                return container_hash

	# RunCBServerContainer()
	#  	Generates a new docker container for cb-server
	# with this challenge binary in it
	def RunCBServerContainer( self, cb_file_path, cb_tag_name ):
		dockerfile = '''# CB-SERVER ''' + cb_tag_name + ''' container
FROM '''+self.repo_name+'''cgc_cbserver:latest
ADD ''' + cb_file_path + ''' /
EXPOSE 1234
ENTRYPOINT ["cb-server"]
CMD ["-p", "1234", "--negotiate", "--insecure", "-d", ".", "''' + cb_file_path + '''"]
'''

		check_container_id_list = self.GetContainerIDFromContainerListByName( self.GetContainerList( name_filter=("cbserver_container_"+cb_tag_name) ), "cromucbserver_container_"+cb_tag_name )
		if ( len( check_container_id_list) > 0 ):
			print "[CBSERVER ALREADY EXISTS]: %s" % check_container_id_list[0]
			return check_container_id_list[0]

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( cb_file_path )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, forcerm=True, tag=(self.repo_name+"cbserver_"+cb_tag_name) )]

		print "[CBSERVER BUILD] Response is: "
		print response		
		container_hash = ContainerHelper.GetHashFromResults( response )

                print "[CBSERVER CONTAINER] hash is: %s\n" % container_hash

                if ( container_hash == None ):
                        return None

		# Start container (impose limits)
                create_results = self.cli.create_container( image=(self.repo_name+"cbserver_"+cb_tag_name), detach=True, name=("cromucbserver_container_"+cb_tag_name) )

		print "[CBSERVER CREATE] Results:"
		print create_results	
		start_results = self.cli.start( container=create_results.get('Id') )	
	
		print "[CBSERVER START] Results:"
		print start_results	
		return response

	def RunCBReplayContainer( self, cb_tag_name, cbserver_container_id, poll_folder ):
		dockerfile = '''# CB-REPLAY ''' + cb_tag_name + ''' container
FROM '''+self.repo_name+'''cgc_cbreplay:latest
ENTRYPOINT ["/run-cb-replay"]
CMD ["1", "1115834a7121b4cd47d622800179c5e392f950d6cf3d167108e06bb0a86a5eb1", "96a087f0f0ee1a9309c2af8fbc25fd302026d22a5bcc18866f988b9ade222e01fbde24aab5b71dcec2209698997ea1a5", "''' + cb_tag_name + '''", "/mnt/poll_files"]
'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )


		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, forcerm=True, tag=(self.repo_name+"cbreplay_"+cb_tag_name) )]

		print "[CBREPLAY BUILD] Response is: "
		print response		
		container_hash = ContainerHelper.GetHashFromResults( response )

                print "[CBREPLAY CONTAINER] hash is: %s\n" % container_hash

                if ( container_hash == None ):
                        return None

		# Start container (impose limits)
                create_results = self.cli.create_container( image=(self.repo_name+"cbreplay_"+cb_tag_name), detach=True, name=("cromucbreplay_container_"+cb_tag_name), volumes=['/mnt/poll_files/'], host_config=self.cli.create_host_config(binds={
	poll_folder: {
		'bind': '/mnt/poll_files/',
		'mode': 'ro',
		}
	}, links={"cromucbserver_container_"+cb_tag_name : 'CBSERVER'})
	)

		print "[CBREPLAY CONTAINER] Create results: "
		print create_results

		start_results = self.cli.start( container=create_results.get('Id') )	
		print "[CBREPALY CONTAINER] Start results: "	
		print create_results
	

		return create_results

        def RemoveContainerByName( self, search_name, retry_count=3 ):
            for _ in range(retry_count):
                try:
                    container_list = self.GetContainerList( name_filter=search_name, show_all=True )

                    container_id_list = self.GetContainerIDFromContainerListByName( container_list, search_name ) 
                    
                    if len(container_id_list) == 0:
                            continue

                    container_id = container_id_list[0]

                    self.cli.remove_container( container=container_id, force=True )
                    
                    retry_fail = False
                except:
                    retry_fail = True

                if retry_fail is False:
                    break

                time.sleep( 4 )

	def StartContainerWithRetry( self, container_id, retry_count=4 ):
            # Try a few times to start the container -- sometimes Docker Swarm just sucks at things
            for _ in range(retry_count):
                try:
                    self.cli.start( container=container_id )
                    start_fail = False
                except docker.errors.NotFound:
                    start_fail = True

                if start_fail is False:
                    break

                print "CBDockerEngine::Attempting to retry start of container: ", container_id
                time.sleep( 4 )

        def RunBuildPollsContainer( self, container_name, poll_seed, poll_save_dir, poll_count, poll_source_dir ):
                
            container_command = " --store_seed --repeat 0 --count " + ("%d"%poll_count) + " --seed " + poll_seed + " --depth 1048575 /mnt/pollsource/machine.py /mnt/pollsource/state-graph.yaml /mnt/pollsave/"

            create_results = self.cli.create_container( image=(self.repo_name+"cgc_pollgenerator:latest"), volumes=['/mnt/pollsource/','/mnt/pollsave/'], entrypoint="/usr/bin/generate-polls", detach=False, tty=True, network_disabled=True, command=container_command, host_config=self.cli.create_host_config(binds={
	poll_source_dir: {
		'bind': '/mnt/pollsource/',
		'mode': 'ro',
		},
        poll_save_dir: {
                'bind': '/mnt/pollsave/',
                'mode': 'rw',
                }
	},
        shm_size="64M")
	)

	    #print "[POLL-GENERATOR CONTAINER] Create results: "
	    #print create_results

	    start_results = self.cli.start( container=create_results.get('Id') )	
	    #print "[POLL-GENERATOR CONTAINER] Start results: "	
	    #print start_results

            # Start just returns None, so return create_results -- this will give us the container ID
            return create_results

        def RunTestPolls( self, csid, connection_id, container_name, throw_count, round_seed, round_secret, round_label, ids_dir, ids_rule_filename, cb_dir, cb_filename, poll_source_dir, pov_source_dir, split_start_pos, split_end_pos, pcap_host, pcap_port ):
            # This will run a test of poll files by spinning up all three containers (CB-SERVER, IDS, and CB-REPLAY)
            if ( self.CheckImageExists( self.repo_name+"cgc_cbids" ) == False ):	
                self.GenIDSBaseImage()

            if ( self.CheckImageExists( self.repo_name+"cgc_cbserver" ) == False ):
                self.GenCBServerBaseImage()

            if ( self.CheckImageExists( self.repo_name+"cgc_cbreplay" ) == False ):
                self.GenCBReplayBaseImage()
          
            # SPIN UP CB-SERVER FIRST! (set timeout to 15 and max connections to 1)
            cbserver_container_command = "1234 " + cb_filename

            try:
                cbserver_create_results = self.cli.create_container( image=(self.repo_name+"cgc_cbserver:latest"), name=(container_name+"_cbserver"), ports=[1234], volumes=['/mnt/cbsource/'], entrypoint="run-cb-server", detach=False, tty=True, network_disabled=False, command=cbserver_container_command, host_config=self.cli.create_host_config(binds={
                cb_dir: {
                        'bind': '/mnt/cbsource/',
                        'mode': 'ro',
                        }
                },
                #cap_add=["SYS_ADMIN"],
                shm_size="64M",
                mem_limit="512M",
                memswap_limit="512M",
                mem_swappiness=0)
                )
                
                #print "CB-SERVER create results: ", cbserver_create_results
                if ( cbserver_create_results is None ):
                    return None

                #cbserver_start_results = self.cli.start( container=cbserver_create_results.get('Id') )	
                cbserver_container_id = cbserver_create_results.get('Id')
                
                # Start cb-server container (with retries)
                self.StartContainerWithRetry( cbserver_container_id )

            except docker.errors.APIError as e:
                logger.error( "Docker::APIError::%s", str(e) )
                if True: #str(e).find("Container created but refresh didn't report it back") >= 0:
                    # FIND IT
                    container_id = None
                    search_name = (container_name+"_cbserver")
                    print "Attempting to refind lost cb-server container and starting it"

                    for try_cur in range(7):
                            time.sleep(4)

                            container_list = self.GetContainerList( name_filter=search_name, show_all=True )

                            container_id_list = self.GetContainerIDFromContainerListByName( container_list, search_name ) 

                            if len(container_id_list) == 0:
                                    continue

                            container_id = container_id_list[0]
                            break

                    if container_id is None:
                            raise

                    # Start cb-server container
                    self.StartContainerWithRetry( container_id )
                    #cbserver_start_results = self.cli.start( container=container_id )	

                    cbserver_container_id = container_id
                else:
                    raise


            # SPIN UP IDS NEXT!
            cbids_container_command = "%d %d \"%s\" \"%s\" %d" % (csid, connection_id, ids_rule_filename, pcap_host, pcap_port)

            try:
                cbids_create_results = self.cli.create_container( image=(self.repo_name+"cgc_cbids:latest"), name=(container_name+"_cbids"), ports=[1235], volumes=['/mnt/idssource/'], entrypoint="run-cb-ids", detach=False, tty=True, network_disabled=False, command=cbids_container_command, host_config=self.cli.create_host_config(binds={
                ids_dir: {
                        'bind': '/mnt/idssource/',
                        'mode': 'ro',
                        }
                }, links={
                    container_name+"_cbserver":"CBSERVER"
                },
                shm_size="64M",
                mem_limit="256M",
                memswap_limit="256M",
                mem_swappiness=0)
                )

                # Start cb-ids container
                #cbids_start_results = self.cli.start( container=cbids_create_results.get('Id') )	

                cbids_container_id = cbids_create_results.get('Id')
                
                self.StartContainerWithRetry( cbids_container_id )

            except docker.errors.APIError as e:
                logger.error( "Docker::APIError::%s", str(e) )
                if True: #str(e).find("Container created but refresh didn't report it back") >= 0:
                    # FIND IT
                    container_id = None
                    search_name = (container_name+"_cbids")
                    print "Attempting to refind lost cb-ids container and starting it"

                    for try_cur in range(7):
                            time.sleep(4)

                            container_list = self.GetContainerList( name_filter=search_name, show_all=True )

                            container_id_list = self.GetContainerIDFromContainerListByName( container_list, search_name ) 

                            if len(container_id_list) == 0:
                                    continue

                            container_id = container_id_list[0]
                            break

                    if container_id is None:
                            raise

                    # Start cb-ids container
                    #cbids_start_results = self.cli.start( container=container_id )	
                    self.StartContainerWithRetry( container_id )

                    cbids_container_id = container_id
                else:
                    raise

            # LAST, SPIN UP CB-REPLAY!
            cbreplay_container_command = "%d \"%s\" \"%s\" \"%s\" /mnt/pollsource/ /mnt/povsource/ %d %d" % (throw_count, round_seed, round_secret, round_label, split_start_pos, split_end_pos)

            if pov_source_dir is None:
                try:
                    cbreplay_create_results = self.cli.create_container( image=(self.repo_name+"cgc_cbreplay:latest"), name=(container_name+"_cbreplay"), volumes=['/mnt/pollsource/'], entrypoint="run-cb-master-replay", detach=False, tty=True, network_disabled=False, command=cbreplay_container_command, host_config=self.cli.create_host_config(binds={
                    poll_source_dir: {
                            'bind': '/mnt/pollsource/',
                            'mode': 'ro',
                            }
                    }, links={
                        container_name+"_cbids":"CBIDS"
                    },
                    shm_size="64M",
                    mem_limit="512M",
                    memswap_limit="512M",
                    mem_swappiness=0)
                    )
                
                    # Start cb-replay container
                    #cbreplay_start_results = self.cli.start( container=cbreplay_create_results.get('Id') )	

                    cbreplay_container_id = cbreplay_create_results.get('Id')
                    
                    self.StartContainerWithRetry( cbreplay_container_id )

                except docker.errors.APIError as e:
                    logger.error( "Docker::APIError::%s", str(e) )
                    if True: #str(e).find("Container created but refresh didn't report it back") >= 0:
                        # FIND IT
                        container_id = None
                        search_name = (container_name+"_cbreplay")
                        print "Attempting to refind lost cb-replay container and starting it"

                        for try_cur in range(7):
                            time.sleep(4)

                            container_list = self.GetContainerList( name_filter=search_name, show_all=True )

                            container_id_list = self.GetContainerIDFromContainerListByName( container_list, search_name ) 

                            if len(container_id_list) == 0:
                                    continue

                            container_id = container_id_list[0]
                            break

                        if container_id is None:
                            raise

                        # Start cb-replay container
                        #cbreplay_start_results = self.cli.start( container=container_id )	
                        self.StartContainerWithRetry( container_id )

                        cbreplay_container_id = container_id
                    else:
                        raise

            else:
                try:
                    cbreplay_create_results = self.cli.create_container( image=(self.repo_name+"cgc_cbreplay:latest"), name=(container_name+"_cbreplay"), volumes=['/mnt/pollsource/', '/mnt/povsource/'], entrypoint="run-cb-master-replay", detach=False, tty=True, network_disabled=False, command=cbreplay_container_command, host_config=self.cli.create_host_config(binds={
                    poll_source_dir: {
                            'bind': '/mnt/pollsource/',
                            'mode': 'ro',
                            },
                    pov_source_dir: {
                            'bind': '/mnt/povsource/',
                            'mode': 'ro',
                        }
                    }, links={
                        container_name+"_cbids":"CBIDS"
                    },
                    shm_size="64M",
                    mem_limit="512M",
                    memswap_limit="512M",
                    mem_swappiness=0)
                    )
                    
                    # Start cb-replay container
                    #cbreplay_start_results = self.cli.start( container=cbreplay_create_results.get('Id') )	
                    cbreplay_container_id = cbreplay_create_results.get('Id')
                        
                    self.StartContainerWithRetry( cbreplay_container_id )

                except docker.errors.APIError as e:
                    logger.error( "Docker::APIError::%s", str(e) )
                    if True: #str(e).find("Container created but refresh didn't report it back") >= 0:
                        # FIND IT
                        container_id = None
                        search_name = (container_name+"_cbreplay")
                        print "Attempting to refind lost cb-replay container and starting it"

                        for try_cur in range(7):
                            time.sleep(4)

                            container_list = self.GetContainerList( name_filter=search_name, show_all=True )

                            container_id_list = self.GetContainerIDFromContainerListByName( container_list, search_name ) 

                            if len(container_id_list) == 0:
                                    continue

                            container_id = container_id_list[0]
                            break

                        if container_id is None:
                            raise

                        # Start cb-replay container
                        #cbreplay_start_results = self.cli.start( container=container_id )	
                        self.StartContainerWithRetry( container_id )

                        cbreplay_container_id = container_id
                    
                    else:
                        raise


            return (cbserver_container_id, cbids_container_id, cbreplay_container_id)


        def PullImageName( self, repository_name, tag_name ):
            pull_results = self.cli.pull( repository=repository_name, tag=tag_name )

            print "Pull results: "
            print pull_results

        def PushImage( self, repository_name, tag_name ):
            push_result = self.cli.push( repository=repository_name, tag=tag_name )

            return push_result

        def PullImage( self, repository_name, tag_name ):
            pull_result = self.cli.pull( repository=repository_name, tag=tag_name )

            return pull_result

	def GenPollGeneratorBaseImage( self, force_reload = False ):
                # Check for base python image 
                if ( self.CheckImageExists( self.repo_name+"cgc_pythonbase" ) == False ):
                    print "cgc_pythonbase not found -- generating!\n"

                    # Rebuild
                    self.GenCBPythonImage( True )

                    # Push
                    self.PushImage( self.repo_name+"cgc_pythonbase", "latest" )

                if ( force_reload == False ):
		    if ( self.CheckImageExists( self.repo_name+"cgc_pollgenerator" ) == False ):	
		        print "Reloading cgc_pollgenerator, as it does not exist!\n"
                    else:
			print "Not loading cgc_pollgenerator as it already exists!\n"
                        return
                else:
                    print "Reload cgc_pollgenerator, force reloading!\n"

		dockerfile = '''# Poll Generator Base Container
FROM '''+self.repo_name+'''cgc_pythonbase:latest
RUN apt-get update -y
RUN apt-get install -y python-dev
RUN apt-get install -y python-pip
RUN pip install numpy
ADD ''' + self.tool_folder_path + '''generate-polls /usr/bin/
ADD ''' + self.tool_folder_path + '''generator /usr/lib/python2.7/generator/
ADD ''' + self.tool_folder_path + '''ansi_x931_aes128.py /usr/lib/python2.7/
ADD ''' + self.tool_folder_path + '''yaml /usr/lib/python2.7/dist-packages/yaml/
ADD ''' + self.tool_folder_path + '''Crypto /usr/lib/python2.7/dist-packages/Crypto/
'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/generate-polls' )
                docker_tarfile.add( self.tool_folder_path + '/generator' ) 
                docker_tarfile.add( self.tool_folder_path + '/ansi_x931_aes128.py' )
                docker_tarfile.add( self.tool_folder_path + '/yaml' )
                docker_tarfile.add( self.tool_folder_path + '/Crypto' )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, forcerm=True, nocache=True, tag=self.repo_name+"cgc_pollgenerator" )]

		print "cgc_pollgenerator build response: "
		print response

		container_hash = ContainerHelper.GetHashFromResults( response )
		
                print "cgc_pollgenerator container hash is: %s\n" % container_hash		

                return container_hash
            
        def GetContainerInfo( self, container_id ):
            # Read container information
            if ( container_id is None ):
                return None

            inspect_info = self.cli.inspect_container( container=container_id )

            if ( inspect_info is None ):
                return None

            return inspect_info
        
        def IsContainerExited( self, container_info ):
            if ( container_info is None ):
                return False

            if ( container_info['State'] is None ):
                return False

            if ( container_info['State']['Status'] is None ):
                return False

            if container_info['State']['Status'] == 'exited':
                return True
            else:
                return False

        def IsContainerRunning( self, container_info ):
            if ( container_info is None ):
                return False

            if ( container_info['State'] is None ):
                return False

            if ( container_info['State']['Status'] is None ):
                return False

            if container_info['State']['Status'] == 'running':
                return True
            else:
                return False

        def GetContainerStartTime( self, container_info ):
            if ( container_info is None ):
                return None

            if ( container_info['State'] is None ):
                return None

            if ( container_info['State']['StartedAt'] is None ):
                return None

            return container_info['State']['StartedAt']

        def GetContainerEndTime( self, container_info ):
            if ( container_info is None ):
                return None

            if ( container_info['State'] is None ):
                return None

            if ( container_info['State']['FinishedAt'] is None ):
                return None

            return container_info['State']['FinishedAt']

        def WaitForContainerExit( self, container_id ):
            while True:
                container_info = self.GetContainerInfo( container_id )

                if self.IsContainerRunning( container_info ):
                    time.sleep( 1 )
                else:
                    break

        def KillAndRemoveContainer( self, container_id ):
            if ( container_id is None ):
                return False

            try:
                remove_result = self.cli.remove_container( container=container_id, force=True )
            except docker.errors.APIError as e:
                return None

            return remove_result

        def GetContainerLogs( self, container_id ):
            if ( container_id is None ):
                return None

            # Return string
            return self.cli.logs( container=container_id, stream=False, stdout=True, stderr=True, timestamps = False )
