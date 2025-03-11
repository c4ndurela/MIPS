		.macro read_int
		li $v0,5
		syscall
		.end_macro

		.macro print_label (%label)
		la $a0, %label
		li $v0, 4
		syscall
		.end_macro

		.macro done
		li $v0,10
		syscall
		.end_macro	

		.macro print_error (%errno)
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
menu:	.ascii "Colecciones de objetos categorizados\n"
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
error:	.asciiz "Error: "
return:	.asciiz "\n"
catName:.asciiz "\nIngrese el nombre de una categoria: "
selCat:	.asciiz "\nSe ha seleccionado la categoria: "
idObj:	.asciiz "\nIngrese el ID del objeto a eliminar: "
objName:.asciiz "\nIngrese el nombre de un objeto: "
success:.asciiz "La operación se realizo con exito\n\n"
indicador: .asciiz " > "
separador: .asciiz " - "
objNotFound: .asciiz "Not Found: Objeto no encontrado en la lista\n"
label201:	.asciiz "No hay categorias\n"
label202:	.asciiz "Existe una sola categoria\n"
label301:	.asciiz "No hay categorias para listar\n"
label401:	.asciiz "No hay categorias para eliminar\n"
label501:	.asciiz "No hay categoria para almacenar el objeto\n"
label601:	.asciiz "No hay categoria creada\n"
label602:	.asciiz "No hay objetos de la categoria para listar\n"
label701:	.asciiz "No existe categoria para eliminar objeto\n"
		.text
main:
	# initialization scheduler vector
	la $t0, schedv
	la $t1, newcategory
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
	sll $v0, $v0, 2         # multiply menu option by 4
	la $t0, schedv 	###carga la direccion del schedv
	add $t0, $t0, $v0 ## a $t0 le suma el valor de $v0
	lw $t1, ($t0)	##en $t1 almaceno el valor de $t0
    	la $ra, main_ret 		# save return address
    	jr $t1					# call menu subrutine
main_ret:
    j main_loop		
main_end:
	done

menu_display:
	# write your code
	print_label(menu)
	read_int
	# test if invalid option go to L1
	bgt $v0, 8, menu_display_L1
	bltz $v0, menu_display_L1
	# else return
	jr $ra
	# print error 101 and try again
menu_display_L1:
	print_error(101)
	j menu_display
	
newcategory:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	la $a0, catName		# input category name
	jal getblock
	move $a2, $v0		# $a2 = *char to category name
	la $a0, cclist		# $a0 = list
	li $a1, 0			# $a1 = NULL
	jal addnode
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist		# update working list if was NULL
newcategory_end:
	li $v0, 0			# return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra

nextcategory:
	lw $t0, wclist		#cargo la categoria actual
	beqz $t0, er201 		#si no hay categoria imprimo error 201
	
	lw $t1, wclist 		#uso una copia para comparar 
	lw $t0, 12($t0) 		#dir cat siguiente
	
	beq $t0, $t1, er202 	#si hay una sola categoria, error 202
	sw $t0, wclist 		#guardas el valor de $t0, en wclist (actualizas el valor de wclist al nodo siguiente)
	lw $t0, 8($t0)		#puntero al nombre 
	print_label(selCat)
	la $a0, 0($t0)		#cargo el valor para imprimir
	li $v0, 4 		#linea para imprimir string
	syscall 			#imprimo en pantalla
	jr $ra

prevcategory:
	lw $t0, wclist		#cargo la categoria actual
	beqz $t0, er201 		#si no hay categoria imprimo error 201
	
	lw $t1, wclist 		#uso una copia para comparar 
	lw $t0, 0($t0) 		#dir cat siguiente
	
	beq $t0, $t1, er202 	#si hay una sola categoria, error 202
	sw $t0, wclist 		#guardas el valor de $t0, en wclist (actualizas el valor de wclist al nodo siguiente)
	lw $t0, 8($t0)
	print_label(selCat)
	la $a0, 0($t0)		#cargo el valor para imprimir
	li $v0, 4 		#linea para imprimir string
	syscall 			#imprimo en pantalla
	jr $ra

listcategories:
	lw $t0, wclist
	lw $t1, cclist		#inicio lista de categoria circular
	beqz $t1, er301 		#lista vacia-> error 301
	lw $t2, cclist
	j list_loop
list_loop:
	beq $t0, $t1, print_equal#si la direccion  es igual a la actual, imprimo mensaje con >
	lw $a0, 8($t1)		#nombre de la categoria
	li $v0, 4
	syscall 			#imprimimos el valor
	lw $t1, 12($t1)	 	# puntero next category
	beq $t1, $t2, list_loop_end #si el nodo siguiente es igual al inicio de la lista circular, termino el bucle
	j list_loop
print_equal:
	lw $t0, 8($t0) 		#desplazo al inicio del nodo actual para imprimir
	lw $t1, 12($t1)	 	#muevo a la direccion de la categoria siguiente

	la $a0, indicador 	#imprimimos el indicador >
	li $v0, 4
	syscall
	la $a0, 0($t0) 		#imprimimos la categoria actual
	li $v0, 4
	syscall
	beq $t1, $t2, list_loop_end #si el nodo siguiente es igual al inicio de la lista circular, termino el bucle
	j list_loop
list_loop_end:
	jr $ra
		
delcategory:
	# a0: node address to delete = direccion del nodo a eliminar
	# a1: list address where node is deleted = direccion de la lista que contiene el nodo
	
	addiu $sp, $sp, -4
	sw $ra, 4($sp)		#recupero el stack
	lw $t0, wclist		#selecciono lista de categorias
	beqz $t0, er401		#si no hay categorias, imprimo error 401
	lw $t0, 4($t0)		#desplazo puntero a lista de objetos
	beqz $t0, del_empty_cat	#elimino categoria vacia
	lw $t1, wclist		#direccion actual
	la $a1, 4($t1)		#direccion de lista de objetos para eliminar
	jal loop_del_obj
	
	lw $ra, 4($sp)	
	addiu $sp, $sp, 4	#restauro stack
	jr $ra
	
loop_del_obj:
	lw $t2, 12($t0)		#puntero a la direccion del siguiente nodo
	add $a0, $0, $t0		# a0 direccion del nodo a eliminar (wclist)
	jal delnode		#eliminamos el nodo
	move $t0, $t2		#muevo el valor de t2 a t0
	beq $a0, $t0, del_empty_cat	#si son iguales, elimino todos los objetos, salto a eliminar categoria
	j loop_del_obj
del_empty_cat:
	# a0: node address to delete = direccion del nodo a eliminar
	# a1: list address where node is deleted = direccion de la lista que contiene el nodo
	lw $a0, wclist		#direccion categoria a eliminar	
	la $a1, cclist		#puntero a lista que contiene la categoria a eliminar
	lw $t0, 12($a0)
	sw $t0, wclist		#actualizo wclist al nodo siguiente
	jal delnode		#llamo para eliminar nodo
	print_label(success)
	
	lw $t1, cclist
	beqz $t1, reset_wclist	#si se eliminaron todas las categorias, restauramos wclist
	
	lw $ra, 4($sp)	
	addiu $sp, $sp, 4	#restauro stack
	jr $ra
reset_wclist:
	sw $0, wclist		#reset wclist a 0
	lw $ra, 4($sp)	
	addiu $sp, $sp, 4	#restauro stack
	jr $ra

newobject:
	##Info para llamar addnode
	#a2  -> puntero al nombre del objeto que lo toma de $v0
	#a0 -> direccion de la lista de objeto
	#a1 -> id = hacer funcion para obtener el id, si es el primero, poner en 1 despues incrementar
	# v0: node address added = retorna direccion del nodo que se agrego
	addiu $sp, $sp, -4	#obtengo el stack
	sw $ra, 4($sp)
	lw $t0, wclist	#cargo la categoria actual
	beqz $t0, er501	#si no existe categoria, lanzo error 501
	
	la $a0, objName	#ingresa el texto a imprimir para pedir el nombre del objeto
	jal getblock
	move $a2, $v0	#muevo el retorno de getblock ($v0) a $a2 (DIRECCION DONDE ALMACENA EL NOMBRE DEL OB)
	lw $a0, wclist				
	la $a0, 4($a0) #cargo la direccion donde se guarda el puntero a objetos
	lw $t0, 0($a0) #guardo el contenido de ese puntero para verificar si es el primero
	beqz $t0, insert_list	# si es 0 el contenido (es decir, no tiene lista de objetos)
				# llamo para introducir la lista
	lw $t0, 0($t0)
	lw $t0, 4($t0) #almaceno el ultimo ID de la lista de objetos
	add $a1, $t0, 1 #incrementamos 1 
make_node:
	jal addnode		
	lw $t0, wclist	#direccion del nodo categoria actual		
	la $t0, 4($t0)	#cargo la direccion donde se guarda el puntero a la lista de objetos
	beqz $t0, first_node #si es el primero salto a crear el primer nodo
end_insert_node:		
	li $v0, 0 # return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra
insert_list:	
	li $a1, 1 #inicializo el ID en 1, porque la lista esta vacia
	j make_node	# salto a la funcion para crear el nodo
first_node:
	sw $v0, 0($t0) #almaceno el valor de $v0, en el inicio de $t0
	j end_insert_node

listobjects:
	lw $t0, wclist	#dir de la categoria actual
	beqz $t0, er601	#si no hay categoria, muestro error 601
	lw $t0, 4($t0)	#dir de la lista de objetos de la categoria y USADO PARA COMPARAR
	beqz $t0, er602	#Si no hay objetos en la categoria, muestro error 602
	
	lw $t1, wclist	#cargo direccion de la categoria actual
	lw $t1, 4($t1)	#cargo direccion donde empieza la lista de objetos para DESPLAZARME
	
print_object:
	la $a0, 4($t1)		#me desplazo a la celda que contiene el ID
	lw $a0, 0($a0)
	beq $a0, $a2, next	#a2 id ingresado por teclado, a0 id de elemento actual
	beqz $a0, print_object_end
	li $v0, 1
	syscall	#imprimo ID
	la $a0, separador
	li $v0, 4
	syscall # imprimo separador
	la $a0, 8($t1)
	lw $a0, 0($a0)
	li $v0, 4
	syscall	#imprimo nombre de objeto
next:
	la $t2, 12($t1)		#almaceno la direccion del proximo nodo
	lw $t2, 0($t2) 		#guardo el valor en t2
	beq $t2, $t0, print_object_end
	la $t1, 0($t2) 		#avanzo a la celda que contiene la direccion del proximo nodo
	j print_object
print_object_end:
	jr $ra

delobject:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	
	lw $t0, wclist		# Categoria actual
	beqz $t0, er701		#si no hay categorias, imprime error
	lw $t1, 4($t0)		# puntero a la lista de objetos de la categoria
	beqz $t1, er701		#si no hay lista de objetos, imprime error
	print_label(idObj)
	read_int	
	add $a2, $0, $v0		# almaceno en a2 el ID a eliminar (obtenido en $v0 por read_int)
	lw $t3, 4($t0)		#puntero a lista de objetos de la categoria (usado para comparar)
del_obj_loop:
	#t1 -> puntero a lista de objetos de la categoria
	#t2 -> valor del ID
	#t3 -> puntero a lista de objeto de la categoria (usado para comparar)
	#a2 -> ID ingresado por teclado
	lw $t2, 4($t1)		# obtengo el id del objeto del puntero al inicio de la lista de objetos
	beqz $t2, not_found	# si no tiene ID, es porque no existen objetos
	beq $t2, $a2, found	# si el ID ingresado es igual al actual, llamo a la funcion found
	lw $t1, 12($t1)		# si no es igual, almaceno la direccion del objeto siguiente
	beq $t3, $t1, not_found	# si la direccion siguiente, es donde empieza la lista,termino de recorrer la lista
				# y no se encontro el elemento
	j del_obj_loop
found:
	#t0 -> direccion de categoria actual que contiene la lista de objetos (wclist)
	#t1 -> direccion del objeto a eliminar
	add $a0, $0, $t1		# $a0 almaceno la direccion del objeto encontrado
	add $a1, $t0, 4		# a1 almaceno el puntero al puntero de la lista de objetos
	jal delnode
	print_label(success)	#se elimino con exito
	# restauro las direcciones y la memoria stack
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra	
not_found:
	print_label(objNotFound)
	jr $ra

# a0: list address (pointer to the list)
# a1: NULL if category or ID if an object
# a2: address return by getblock	<--- la direccion donde almacena el texto
# v0: node address added <--- Return
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

# a0: node address to delete = direccion del nodo a eliminar
# a1: list address where node is deleted = direccion de la lista que contiene el nodo
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

er201:
	print_error(201)
	print_label(label201)
	jr $ra
er202:
	print_error(202)
	print_label(label202)
	jr $ra
er301:
	print_error(301)
	print_label(label301)
	jr $ra
er401:
	print_error(401)
	print_label(label401)
	jr $ra
er501:
	print_error(501)
	print_label(label501)
	jr $ra
er601:
	print_error(601)
	print_label(label601)
	jr $ra
er602:
	print_error(602)
	print_label(label602)
	jr $ra
er701:
	print_error(701)
	print_label(label701)
	jr $ra
