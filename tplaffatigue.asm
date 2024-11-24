		.macro read_int #read int del usuario 
		li $v0,5        #read, almacenar en v0
		syscall
		.end_macro

		.macro print_label (%label) #print string en consola
		la $a0, %label 
		li $v0, 4
		syscall
		.end_macro

		.macro done #finalizar el programa
		li $v0,10
		syscall
		.end_macro	

		.macro print_error (%errno) #print msg error + codigo
		print_label(error)
		li $a0, %errno
		li $v0, 1
		syscall
		print_label(return)
		.end_macro
		
	.data
slist:	.word 0
cclist: .word 0
wclist: .word 0
schedv: .space 32
menu:	.ascii "Colecciones de objetos categorizados \n"
		.ascii "====================================\n"
		.ascii "1-Nueva categoria\n"
		.ascii "2-Siguiente categoria\n"
		.ascii "3-Categoria anterior\n"
		.ascii "4-Listar categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Anexar objeto a la categoria actual\n"
		.ascii "7-Listar objetos de la categoria\n"
		.ascii "8-Borrar objeto de la categoria\n"
		.ascii "0-Salir\n"
		.asciiz "Ingrese la opcion deseada: "
error:		.asciiz "Error: "
return:		.asciiz "\n"
catName:	.asciiz "\nIngrese el nombre de una categoria: "
selCat:		.asciiz "\nSe ha seleccionado la categoria: "
idObj:		.asciiz "\nIngrese el ID del objeto a eliminar:  "
objName:	.asciiz "\nIngrese el nombre de un objeto: "
success:	.asciiz "La operacion se realizo con exito\n\n"
failure:	.asciiz "La operacion NO se pudo realizar."

		.text
main:
	# initialization scheduler vector
	la $t0, schedv
	la $t1, newcaterogy
	sw $t1, 0($t0)
	la $t1, nextcategory
	sw $t1, 4($t0)
	la $t1, prevcategory
	sw $t1, 8($t0)
	la $t1, listcategories
	sw $t1, 12($t0)
	la $t1, delcategory
	sw $t1, 16($t0)
	la $t1, newobject
	sw $t1, 20($t0)
	la $t1, listobjects
	sw $t1, 24($t0)
	la $t1, delobject
	sw $t1, 28($t0)
main_loop:
	# show menu
	jal menu_display
	beqz $v0, main_end
	addi $v0, $v0, -1		# dec menu option
	sll $v0, $v0, 2                 # multiply menu option by 4
	la $t0, schedv
	add $t0, $t0, $v0
	lw $t1, ($t0)
  	la $ra, main_ret 		# save return address
  	jr $t1		         	# call menu subrutine


	
# NEW CATEGORY FUNCTION 

newcaterogy:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	la $a0, catName		# input category name
	jal getblock
	move $a2, $v0		# $a2 = *char to cateogry name
	la $a0, cclist		# $a0 = list
	li $a1, 0		# $a1 = NULL
	jal addnode
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist		# update working list if was NULL
newcategory_end:
	print_label(success)
	li $v0, 0		# return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra

# NEXT CAATEGORY FUNCTION

nextcategory:
    lw $t0, wclist 
    beqz $t0, err201 	# no categories print error 201
    
    lw $t1, wclist 	 # wwclist copy for compare
    lw $t0, 12($t0)
     
    beq $t0, $t1, err202 	# one category print error 202
    sw $t0, wclist 	        # save wclist from register
    lw $t0, 8($t0) 
    print_label(selCat)
    la $a0, 0($t0) 	      #print selected category
    li $v0, 4 	
    syscall 
    jr $ra
		
err201:
	print_error(201)
	jr $ra

err202:
	print_error(202)
	jr $ra


# PREVIOUS CATEGORY FUNCTION

prevcategory:
	lw $t0, wclist 
	beqz $t0, err201 	# no categories print error 201
	
  	lw $t1, wclist 	        # wclist copy for compare
  	lw $t0, 0($t0) 
  	
        beq $t0, $t1, err202 	# one category print error 202
        sw $t0, wclist 	
        lw $t0, 8($t0)
        print_label(selCat)
        la $a0, 0($t0)  	#print selected category
        li $v0, 4 	
        syscall 
        jr $ra


# LIST CATEGORIES FUNCTION - ver

# DELETE CATEGORIES FUNCTION  - ver

# NEW OBJECT FUNCTION -corregir

newobject:
	lw $t0, wclist
	beqz $t0, err501    # no categories print error 401
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	
	la $a0, objName
	jal getblock		# get memory block
	
	move $a2, $v0
	lw $a0, wclist
	la $a0, 4($a0)
	lw $t0, 0($a0)
	beqz $t0, create_list		# if no objects create new list
	lw $t0, 0($t0)
	lw $t0, 4($t0)
	addi $a1, $t0, 1		# increments the old ID 
	
create_node:
	jal addnode	# add node subrutine
	lw $t0, wclist
	la $t0, 4($t0)
	beqz $t0, first_object		# first object link to the first pointer
	
newobject_end:
	li $v0, 0			# return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra

create_list:
	li $a1, 1		# initialize ID
	j create_node
	
first_object:
	sw $v0, 0($t0)		#store $v0 in $t0's start 
	j newobject_end
	

err501:
print_error(501)
j newobject_end


# LIST OBJECTS FUNCTION

listobjects:
	lw $t0, wclist
	beqz $t0, err601	# no categories
	lw $t0, 4($t0)
	beqz	$t0, err602	# no objects
	
	lw $t1, wclist
	lw $t1, 4($t1)
	lw $t2, wclist		# set temps
	lw $t2, 4($t2)
	j loop_listobj
	
loop_listobj:
	la $a0, 4($t1)
	lw $a0, ($a0)
	li $v0, 1 			# print ID object
	syscall
	print_label(idSymbol)	# print "->"
	la $a0, 8($t1)
	lw $a0, ($a0)
	li $v0, 4 			# print object name
	syscall
	lw $t1,12($t1)      	# next node
	beq $t1, $t2, endloop_obj		# end verification ( $t1 == cclist)
	j loop_listobj
	
endloop_obj:
	jr $ra

err601:
	print_error(601)
	jr $ra

err602:
	print_error(602)
	jr $ra


# DELETE OBJECTS FUNCTION

delobject: 
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	
	lw $t0, wclist
	beqz $t0, err701	# no categories
	
	lw $t1, 4($t0)		# list objects' direction
	beqz $t1, err701	#no objects
	print_label(idObj)
	read_int		# return in $v0 the input integer
	add $a2, $0, $v0	
	lw $t2, 4($t0)		#pointer to object list to compare 
	
delObjects_loop:
	lw $t3, 4($t1)	# pointer to ID object 
	beqz $t3, notfound
	beq $t3, $a2, found 		#compare object ID == input ID
	lw $t1, 12($t1)		#next object
	beq $t2, $t1, notfound
	j delObjects_loop
	
found:
	add $a0, $0, $t1		#store direction found object 
	add $a1, $t0, 4		# $a1 store pointer to obecjt list
	jal delnode
	print_label(success)
	
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra
	
notfound:
	print_label(failure)		# fail message
	jr $ra
	
err701:
	print_error(701)
	jr $ra
# a0: list address (pointer to the list)
# a1: NULL if category or ID if an object
# a2: address return by getblock
# v0: node address added
addnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	jal smalloc
	sw $a1, 4($v0) # set node content
	sw $a2, 8($v0)
	lw $a0, 4($sp)
	lw $t0, ($a0) # first node address
	beqz $t0, addnode_empty_list
addnode_to_end:
	lw $t1, ($t0) # last node address
 	# update prev and next pointers of new node
	sw $t1, 0($v0)
	sw $t0, 12($v0)
	# update prev and first node to new node
	sw $v0, 12($t1)
	sw $v0, 0($t0)
	j addnode_exit
addnode_empty_list:
	sw $v0, ($a0)
	sw $v0, 0($v0)
	sw $v0, 12($v0)
addnode_exit:
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra

# a0: node address to delete
# a1: list address where node is deleted
delnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	lw $a0, 8($a0) # get block address
	jal sfree # free block
	lw $a0, 4($sp) # restore argument a0
	lw $t0, 12($a0) # get address to next node of a0 node
	beq $a0, $t0, delnode_point_self
	lw $t1, 0($a0) # get address to prev node
	sw $t1, 0($t0)
	sw $t0, 12($t1)
	lw $t1, 0($a1) # get address to first node again
	bne $a0, $t1, delnode_exit
	sw $t0, ($a1) # list point to next node
	j delnode_exit
delnode_point_self:
	sw $zero, ($a1) # only one node
delnode_exit:
	jal sfree
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra

 # a0: msg to ask
 # v0: block address allocated with string
getblock:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	li $v0, 4
	syscall
	jal smalloc
	move $a0, $v0
	li $a1, 16
	li $v0, 8
	syscall
	move $v0, $a0
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra

smalloc:
	lw $t0, slist
	beqz $t0, sbrk
	move $v0, $t0
	lw $t0, 12($t0)
	sw $t0, slist
	jr $ra
sbrk:
	li $a0, 16 # node size fixed 4 words
	li $v0, 9
	syscall # return node address in v0
	jr $ra

sfree:
	lw $t0, slist
	sw $t0, 12($a0)
	sw $a0, slist # $a0 node address in unused list
	jr $ra
