.data
displayaddr:	.word 0x2000
matAaddr:	.word 0x2400
matBaddr:	.word 0x2800
backColor:	.word 0x00BEBEBE
lifeColor:	.word 0x00000000
inputAddr:	.word 0x3200
stopString:	.string "STOP"
readString:	.string "Insira a coordenada no formato 'i, j' seguido de enter. Um numero acima de 15 ou abaixo de 0 nao e valido. 'STOP' termina a aquisicao de valores:"

.text
# 'main' routine
# Prepare the game, calling the adequate functions
main:		
		# load memory content to s registers
		lw s0,displayaddr
		lw s1,matAaddr
		lw s2,matBaddr
		lw s3,backColor
		lw s4,lifeColor
		la s5,readString
		lw s6,inputAddr
		la s7,stopString
		
		# initiate the two matrixes
		mv a0,s1
		call initiate_mat
		mv a0,s2
		call initiate_mat	

# 'prepare_game' routine:
# Get the input from user, and prepare the two matrixes for the game		
prepare_game:			
		li a7,4
		mv a0,s5
		ecall			# print the string with print instructions
		# get the coordinates
prepare_loop:	lb t5,0(s7)		# content of first byte from stopString
		mv a0,s6		# get input adress
		li a1,7
		li a7,8
		ecall			# read string with coordinates
		lb t0,0(a0)		# get first char
		beq t0,t5,prepG_cont	# continue preparatoin if STOP sign has been reached
		call convertString
		# verify if i and j values are valid
		li t6,15		# constant with maximum value
		bgtu a2,t6,prepare_loop
		blt a2,zero,prepare_loop
		bgtu a1,t6,prepare_loop
		blt a1,zero,prepare_loop
		mv a0,a1
		mv a1,a2
		mv a2,s1
		call write		# write the point in the matrix
		b prepare_loop		# get next coordinate
prepG_cont:	mv a0,s2
		mv a1,s1
		call copym		# copy matrix A into B

# 'game' routine:
# Analize the matrix multiple times to see who survives, dies or born. Stop when there is none left.
game:		
		mv s11,zero		# verify if there were any changes
		mv a4,zero		# i iterator
game_loop1:	mv a5,zero		# j iterator
		# read the neighborhood:
game_loop2:	mv a2,s1		# matrix A address in a2 ('write' function)
		# i-1,j-1
		addi a0,a4,-1
		addi a1,a5,-1
		call readm
		mv a6,a3
		# i-1,j
		mv a1,a5
		call readm
		add a6,a6,a3
		# i-1,j+1
		addi a1,a5,1
		call readm
		add a6,a6,a3
		# i,j-1
		mv a0,a4
		addi a1,a5,-1
		call readm
		add a6,a6,a3
		# i,j+1
		addi a1,a5,1
		call readm
		add a6,a6,a3
		# i+1,j-1
		addi a0,a4,1
		addi a1,a5,-1
		call readm
		add a6,a6,a3
		# i+1,j
		mv a1,a5
		call readm
		add a6,a6,a3
		# i+1,j+1
		addi a1,a5,1
		call readm
		add a6,a6,a3
		# read i,j coordinate
		mv a0,a4
		mv a1,a5
		call readm
		mv a2,s2		# matrix B address in a2 ('write' function)
		beqz a3,nolife		# jump if there is no life in the analised point
haslife:	li t0,3
		bgtu a6,t0,death	# kill by hunger
		li t0,2
		bltu a6,t0,death	# kill by solitude
		b game_cont
death:		call write		# modify the matrix to reflect death
		li s11,1		# sinalize change
		b game_cont
nolife:		li t0,3
		beq t0,a6,born		# create new life if there are three bacteria nearby
		b game_cont
born:		call write		# modify the matrix to reflect life
		li s11,1		# sinalize change
game_cont:	addi a5,a5,1		# increase j
		li t0,15		
		bleu a5,t0,game_loop2	# go to loop 2 if j <= 15
		addi a4,a4,1		# increase i 
		bleu a4,t0,game_loop1	# go to loop 1 if i <= 15
		mv a0,s1
		call plot		# plot the old matrix into display
		mv a0,s1
		mv a1,s2
		call copym		# copy matrix B into A
		bnez s11,game		# continue game if there were any changes

# 'exit' routine:
# Emitis signal to finish the game to the system.		
exit:		
		li a7,10
		ecall
			
# 'initiate_mat' function:
# Initiate a 16x16 bytes matrix with zeros.
# Input: a0 - matrix address
initiate_mat:	
		li t0,256		# iterator to know when to stop the loop
inimat_loop:	addi t0,t0,-1
		add t1,a0,t0
		sb zero,0(t1)		# store '0' in matrix
		bnez t0,inimat_loop
		ret
		
# 'convertString' function:
# Get the i and j coordinates from input string
# Input: a0 - string address
# Outputs: a1 - i, a2 - j 
convertString:	
		li t3,10		# constant to multiply
get_i:		lb t0,0(a0)		# get the first char
		addi a0,a0,1
		lb t1,0(a0)		# get the second char
		addi a0,a0,1
		addi t0,t0,-48		# convert ascii char to int number
		addi t1,t1,-48		# convert ascii char to int number
		mv a1,t0
		blt t1,zero,get_j	# if the second char is not a 0-9 digit, consider only the fisrt char to i value
		mul a1,a1,t3		# multiply the most significant digit by 10
		add a1,a1,t1		# add the least significant digit
		addi a0,a0,1		# discard char
get_j:		addi a0,a0,1		# discard char
		lb t0,0(a0)		# get next char
		addi a0,a0,1		
		lb t1,0(a0)		# get next char
		addi t0,t0,-48		# convert ascii char to int number
		addi t1,t1,-48		# convert ascii char to int number
		mv a2,t0
		blt t1,zero,cvtStr_cont	# if the second char is not a 0-9 digit, consider only the fisrt char to j value
		mul a2,a2,t3		# multiply the most significant digit by 10
		add a2,a2,t1		# add the least significant digit
cvtStr_cont:	ret		
				
# 'copym' function:
# Copy the content of a matrix to another
# Inputs: a0 - address of destination matrix, a1 - address of source matrix		  
copym:		
		li t0,256		# maximum value t1 can reach
		li t1,0			# iterator
copym_loop:	add t2,t1,a1
		lb t3,0(t2)		# load byte from src matrix
		add t2,t1,a0
		sb t3,0(t2)		# store byte in dst matrix
		addi t1,t1,1
		bne t0,t1,copym_loop
		ret
		
# 'readm' function:
# Reads the (i,j) element in matrix
# Inputs: a0 - i; a1 - j; a2 - matrix address
# Output: a3 - Element in the (i,j) coordinate
readm:		
		mv a3,zero		#initiate output with zero
		li t2,15		# constant to verify coordinates
		# verify vality of the coordinates
		bgtu a0,t2,readm_ret
		blt a0,zero,readm_ret
		bgtu a1,t2,readm_ret
		blt a1,zero,readm_ret
		li t2,16		# constant to multiply
		mul t1,t2,a1		# multpliy the j coordinate by 16
		add t1,t1,a0		# add (16*j) with i to find the matrix position
		add t0,a2,t1		# add the matrix position with the matrix address to find the byte address
		lb a3,0(t0)
readm_ret:	ret
		
# 'write': function
# Invert the (i,j) element value in matrix
# Inputs: a0 - i; a1 - j; a2 - matrix address
write:				
		li t2,16		
		mul t1,t2,a1		# multpliy the j coordinate by 16
		add t1,t1,a0		# add (16*j) with i to find the matrix position
		add t0,a2,t1		# add the matrix position with the matrix address to find the byte address
		lb t3,0(t0)		
		beqz t3, write_1
write_0:	li t4,0		# invert the content of the coordinate
		b write_save
write_1:	li t4,1
write_save:	sb t4,0(t0)
		ret																			
		
# 'plot' function:
# Plot the given matrix in the bitmap displyay.
# Inputs: a0 - Matrix to be ploted; s0 - display address; s3 - backgorund color; s4 - life color 		
plot:		
		mv t0,s0
		mv t1,a0
		li a0,2000		# tempo para o sistema "dormir"
		li a7,32		# syscall para 'sleep'
		li t6,0x2400		# constant with the biggest value t0 can reach
plot_loop:	lb t2,0(t1)		# get information in t1 byte of the matrix
		beqz t2,printnolife
printlife:	sw s4,0(t0)		# store the life color if the information of t1 is 1
		b verify_plot
printnolife:	sw s3,0(t0)		# store the background color if the information of t1 is 0
verify_plot:	addi t0,t0,4		# increment the display iterator by four (4 bytes word)
		addi t1,t1,1		# increment the matrix iterator by 1 (1 byte)
		bne t0,t6,plot_loop
		ecall			#fazer o sistema "dormir"
		ret	