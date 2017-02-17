#!/usr/bin/env python

import docker
from io import BytesIO
from StringIO import StringIO
import tarfile
import binascii
import parse

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
	def __init__(self, cert_path, cb_folder_path, tool_folder_path, image_folder_path, repo_name ):
                tls_config = docker.tls.TLSConfig( client_cert=(cert_path+'/client.pem', cert_path+'/client-key.pem'), verify=cert_path+'/ca.pem' )

                self.cli = docker.Client( base_url="https://master1:3000", tls=tls_config )

		# Save path to CB containing folder
		self.cb_folder_path = cb_folder_path

		# Save path to folder containing tools (cb-server, cb-replay, etc.)
		self.tool_folder_path = tool_folder_path

                # Path to image files
                self.image_folder_path = image_folder_path

                # Remember repository name
                self.repo_name = repo_name

                print "Repo name is: %s\n" % self.repo_name

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

			load_results = self.LoadImageFromFile( "cgc_base_ubuntu.tz", self.repo_name+"cgc_ubuntu" )

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

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag=self.repo_name+"cgc_pythonbase" )]

		print "cgc_pythonbase build response: "
		print response
		
                container_hash = ContainerHelper.GetHashFromResults( response )

		print "cgc_pythonbase container hash is: %s\n" % container_hash		

	def GenCBProxyBaseImage( self, force_reload = False ):
                # Check for base python image 
                if ( self.CheckImageExists( self.repo_name+"cgc_pythonbase" ) == False ):
                    print "cgc_pythonbase not found -- generating!\n"

                    # Rebuild
                    self.GenCBPythonImage( True )

                    # Push
                    self.PushImage( "master1:5000/cromu/cgc_pythonbase", "latest" )

                if ( force_reload == False ):
		    if ( self.CheckImageExists( self.repo_name+"cgc_cbproxy" ) == False ):	
		        print "Reloading cgc_cbproxy, as it does not exist!\n"
                    else:
			print "Not loading cgc_cbproxy as it already exists!\n"
                        return
                else:
                    print "Reload cgc_cbproxy, force reloading!\n"

		dockerfile = '''# CB Proxy Base Container
FROM '''+self.repo_name+'''cgc_pythonbase:latest
ADD ''' + self.tool_folder_path + '''/cb-proxy /usr/bin/
RUN mkdir /usr/lib/python2.7/ids
ADD ''' + self.tool_folder_path + '''/ids/base.py /usr/lib/python2.7/ids/
ADD ''' + self.tool_folder_path + '''/ids/ids_parser.py /usr/lib/python2.7/ids/
ADD ''' + self.tool_folder_path + '''/ids/__init__.py /usr/lib/python2.7/ids/
ADD ''' + self.tool_folder_path + '''/ids/rule_options.py /usr/lib/python2.7/ids/
ADD ''' + self.tool_folder_path + '''/ids/libre2.a /usr/lib/i386-linux-gnu/
ADD ''' + self.tool_folder_path + '''/ids/libre2.so /usr/lib/i386-linux-gnu/
ADD ''' + self.tool_folder_path + '''/ids/libre2.so.1 /usr/lib/i386-linux-gnu/
ADD ''' + self.tool_folder_path + '''/ids/libre2.so.1.0.0 /usr/lib/i386-linux-gnu/
ADD ''' + self.tool_folder_path + '''/ids/re2.py /usr/lib/python2.7/dist-packages/
ADD ''' + self.tool_folder_path + '''/ids/re2.pyc /usr/lib/python2.7/dist-packages/
ADD ''' + self.tool_folder_path + '''/ids/_re2.so /usr/lib/python2.7/dist-packages/
'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/cb-proxy' )
                docker_tarfile.add( self.tool_folder_path + '/ids' ) 
                '''
                docker_tarfile.add( self.tool_folder_path + '/ids/base.py' )
                docker_tarfile.add( self.tool_folder_path + '/ids/ids_parser.py' )
                docker_tarfile.add( self.tool_folder_path + '/ids/__init__.py' )
                docker_tarfile.add( self.tool_folder_path + '/ids/rule_options.py' )
                '''

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag=self.repo_name+"cgc_cbproxy" )]

		print "cgc_cbproxy build response: "
		print response

		container_hash = ContainerHelper.GetHashFromResults( response )

		print "cgc_cbproxy container hash is: %s\n" % container_hash		

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
ADD ''' + self.tool_folder_path + '''/cb-replay /usr/bin/
ADD ''' + self.tool_folder_path + '''/cb-replay-pov /usr/bin/
ADD ''' + self.tool_folder_path + '''/prf.py /usr/bin/
ADD ''' + self.tool_folder_path + '''/cb-master-replay /usr/bin/
ADD ''' + self.tool_folder_path + '''/run-cb-replay /
'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/cb-replay' )
		docker_tarfile.add( self.tool_folder_path + '/cb-replay-pov' )
                docker_tarfile.add( self.tool_folder_path + '/prf.py' )
                docker_tarfile.add( self.tool_folder_path + '/cb-master-replay' )
		docker_tarfile.add( self.tool_folder_path + '/run-cb-replay' )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag=self.repo_name+"cgc_cbreplay" )]

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
ADD ''' + self.tool_folder_path + '''cb-server /usr/bin
'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/cb-server' )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag=self.repo_name+"cgc_cbserver" )]

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
ADD ''' + self.cb_folder_path + cb_file_path + ''' /
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

		docker_tarfile.add( self.cb_folder_path + '/' + cb_file_path )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag=(self.repo_name+"cbserver_"+cb_tag_name) )]

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

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag=(self.repo_name+"cbreplay_"+cb_tag_name) )]

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

	def RunCBContainer( self, cb_tag_name ):
                # TODO: Run all (3) containers together (cbreplay, cbproxy, cbserver)
		print "TODO:"

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

if __name__ == "__main__":
        cbDocker = CBDockerEngine( "certs/", "cbs/", "tools/", "images/", "master1:5000/cromu/" )

        cbDocker.PullImageName( "master1:5000/cromu/swarm_32bit", "latest" )
'''
	output = cbDocker.RunCBServerContainer( "LUNGE_00001", "LUNGE_00001" )

	output2 = cbDocker.RunCBReplayContainer( "LUNGE_00001", output, "/wa_storage/data/test/LUNGE_00001/polls/" )

'''

'''
	print "Container List"
	container_list_results = cbDocker.GetContainerList( show_all=True ) #"CADET_00002_extra" )
	print container_list_results

	container_id_list = cbDocker.GetContainerIDFromContainerListByName( container_list_results, "cromucbserver_CADET_00002" )

	print container_id_list
'''	
