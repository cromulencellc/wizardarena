#!/usr/bin/env python

from docker import Client
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
	def __init__(self, cb_folder_path, tool_folder_path ):
		self.cli = Client( base_url="tcp://master1:2375" )

		# Save path to CB containing folder
		self.cb_folder_path = cb_folder_path

		# Save path to folder containing tools (cb-server, cb-replay, etc.)
		self.tool_folder_path = tool_folder_path

		# Build CB Server base container
		self.GenCBServerBaseImage( )

		# Build CB Replay base container
		self.GenCBReplayBaseImage( )
	
	def GetContainerList( self, name_filter="", show_all=False ):
		if ( len(name_filter) > 0 ):
			#filter_list = { "label" : ("name="+name_filter) }
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
			print "File not found!"
			return None

		#print "Image file loaded size=%d\n" % len(image_file_data)

		load_results = self.cli.import_image_from_data( data=image_file_data, repository="cromu", tag=image_name )

		return load_results 

	def LoadUbuntuImage( self ):
		# First check for 32bit/ubuntu:14.04
		image_search = self.cli.images( )

		load_image = True
		if ( image_search == None ):
			load_image = True

		for item in image_search:
			if ( item["RepoTags"] != ("cromu:cgc_ubuntu") ):
				load_image = False
				break

		if ( load_image ):	
			load_results = self.LoadImageFromFile( "cgc_base_ubuntu.tz", "cgc_ubuntu" )

			print "Ubuntu image loaded!"
		else:
			print "Ubuntu image not loaded (already exists)!"

			#print load_results

		#print image_search

	def GenCBReplayBaseImage( self ):
		self.LoadUbuntuImage()

		dockerfile = '''# CB Server Base Container
FROM cromu:cgc_ubuntu
RUN apt-get install -y python
ADD ''' + self.tool_folder_path + '''cb-replay /usr/bin
'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/cb-replay' )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag="cromu:cgc_cbreplay" )]

		container_hash = ContainerHelper.GetHashFromResults( response )

		print "CB Replay container is: %s\n" % container_hash		

		if ( container_hash == None ):
			return None
		
		return container_hash
		
	def GenCBServerBaseImage( self ):
		self.LoadUbuntuImage()

		dockerfile = '''# CB Server Base Container
FROM cromu:cgc_ubuntu
ADD ''' + self.tool_folder_path + '''cb-server /usr/bin
'''

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/cb-server' )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag="cromu:cgc_cbserver" )]

		print "First response: "
		print response

		container_hash = ContainerHelper.GetHashFromResults( response )

		print "Container hash is: %s\n" % container_hash		

		if ( container_hash == None ):
			return None
		
		return container_hash
		
	# RunCBServerContainer()
	#  	Generates a new docker container for cb-server
	# with this challenge binary in it
	def RunCBServerContainer( self, cb_file_path, cb_tag_name ):
		dockerfile = '''# CB-SERVER ''' + cb_tag_name + ''' container
FROM cromu:cgc_cbserver
ADD ''' + self.cb_folder_path + cb_file_path + ''' /
EXPOSE 1234
ENTRYPOINT ["cb-server"]
CMD ["-p", "1234", "--negotiate", "--insecure", "-m", "1", "-d", ".", "''' + cb_file_path + '''"]
'''

		check_container_id_list = self.GetContainerIDFromContainerListByName( self.GetContainerList( name_filter=("cbserver_"+cb_tag_name) ), "cromucbserver_"+cb_tag_name )
		if ( len( check_container_id_list) > 0 ):
			print "[CBSERVER ALREADY EXISTS]: %s" % check_container_id_list[0]
			return check_container_id_list[0]

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		#docker_tarfile.add( self.tool_folder_path + '/cb-server' )
		docker_tarfile.add( self.cb_folder_path + '/' + cb_file_path )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag=("cromu:cbserver_"+cb_tag_name) )]

		print "[CBSERVER BUILD] Response is: "
		print response		
		container_hash = ContainerHelper.GetHashFromResults( response )

                print "[CBSERVER CONTAINER] hash is: %s\n" % container_hash

                if ( container_hash == None ):
                        return None

		# Start container (impose limits)
		create_results = self.cli.create_container( image=("cromu:cbserver_"+cb_tag_name), detach=True, name=("cromucbserver_"+cb_tag_name) )

		print "[CBSERVER CREATE] Results:"
		print create_results	
		start_results = self.cli.start( container=create_results.get('Id') )	
	
		print "[CBSERVER START] Results:"
		print start_results	
		return response

	def RunCBReplayContainer( self, cb_tag_name, cbserver_container_id, poll_folder ):
		dockerfile = '''# CB-REPLAY ''' + cb_tag_name + ''' container
FROM cromu:cgc_cbreplay
ADD ''' + self.tool_folder_path + '''/run-cb-replay /
ENTRYPOINT ["/run-cb-replay"]
CMD ["/mnt/poll_files/GEN_00000.xml"]
'''

		#cbserver_container_name = cbDocker.GetContainerInfoByID( cbserver_container_id )['Names'][0]
		#if ( cbserver_container_name == None ):
		#	return None

		docker_filedata = BytesIO( )
		docker_tarfile = tarfile.open( fileobj=docker_filedata, mode="w:gz" )
		
		dockerfile_ti = tarfile.TarInfo("Dockerfile")
		dockerfile_ti.size = len(dockerfile)

		docker_tarfile.addfile( dockerfile_ti, StringIO( dockerfile ) )

		docker_tarfile.add( self.tool_folder_path + '/run-cb-replay' )

		docker_tarfile.close()

		response = [line for line in self.cli.build( fileobj=docker_filedata.getvalue(), custom_context=True, encoding='gzip', rm=True, tag=("cromu:cbreplay_"+cb_tag_name) )]

		print "[CBREPLAY BUILD] Response is: "
		print response		
		container_hash = ContainerHelper.GetHashFromResults( response )

                print "[CBREPLAY CONTAINER] hash is: %s\n" % container_hash

                if ( container_hash == None ):
                        return None

		# Start container (impose limits)
		create_results = self.cli.create_container( image=("cromu:cbreplay_"+cb_tag_name), detach=True, name=("cromucbreplay_"+cb_tag_name), volumes=['/mnt/poll_files/'], host_config=self.cli.create_host_config(binds={
	'/wa_storage/data/rounds/1/poller/': {
		'bind': '/mnt/poll_files/',
		'mode': 'ro',
		}
	}, links={"cromucbserver_"+cb_tag_name : 'CBSERVER'})
	)

		print "[CBREPLAY CONTAINER] Create results: "
		print create_results

		start_results = self.cli.start( container=create_results.get('Id') )	
		print "[CBREPALY CONTAINER] Start results: "	
		print create_results
	

		return create_results

	def RunCBContainer( self, cb_tag_name ):
		print "TODO:"
 
if __name__ == "__main__":
	cbDocker = CBDockerEngine( "cbs/", "tools/" )

	output = cbDocker.RunCBServerContainer( "CADET_00002", "CADET_00002" )
	
	output2 = cbDocker.RunCBReplayContainer( "CADET_00002", output, "/wa_storage/data/rounds/1/poller/" )

'''
	print "Container List"
	container_list_results = cbDocker.GetContainerList( show_all=True ) #"CADET_00002_extra" )
	print container_list_results

	container_id_list = cbDocker.GetContainerIDFromContainerListByName( container_list_results, "cromucbserver_CADET_00002" )

	print container_id_list
'''	
