//
//  DoublyLinkedList.swift
//  Inspec
//
//  Created by Justin Cook on 7/19/21.
//
//Doubly Linked List Implementation for Generic types

import Foundation

/** A node is an entity within a linked list that maintains a specific type of value and retains a pointer to the next and or previous element in the linked list depending on whether the list is doubly or singly linked by pointers
 - Each node can contain a generic data type 'T' which allows the list to be used to store any type, regardless of whether it's comparative or not
 
 - Author: Justin Cook
 */
public class Node<T:Equatable>{
    /** The type of entity stored by this linked list*/
    var value: T
    /** The single pointer pointing to the next node in the linked list, this is the first link, making this singly linked list*/
    var next: Node<T>?
    /** Second pointer pointing to the previous element in the linked list, this is the second link, making this a doubly linked list. The var is declared as weak in order to avoid ownership cycle conflicts in which nodes will be kept alive in memory, thus to ensure this cycle is broken after nodes are deleted the previous pointer is kept as a weak var*/
    weak var previous: Node<T>?
    
    /** Initialize the node object with a generic value 'T'*/
    init(value: T){
        self.value = value
    }
    
    /** compare the value of the current node to the passed node*/
    public func equals(node: Node?)->Bool{
        if(self.value == node?.value){
            return true
        }
        else{
            return false
        }
    }
}

/**
 A doubly linked list of nodes that are connected via pointer references to the previous and next node object until the 'tail' indicator of a nil value is reached
 - Each node can contain a generic data type 'T' which allows the list to be used to store any type, regardless of whether it's comparative or not
 
 - Author: Justin Cook
 */
public class LinkedList<T:Equatable>{
    /** Head and tail of the linked list with the head being privatized to this file's classes alone*/
    fileprivate var head: Node<T>?
    /** Tail is only accessed by this class*/
    private var tail: Node<T>?
    
    /** getter method: return true or false depending on whether the head of the list is nil or not*/
    public var isEmpty: Bool{
        return head == nil
    }
    
    /** getter method: return the head of the linked list when referencing first*/
    public var first: Node<T>?{
        return head
    }
    
    /** getter method: return the tail of the linked list when referencing last*/
    public var last: Node<T>?{
        return tail
    }
    
    /** Append an element to the list that's not already present inside of it*/
    public func appendUniqueElement(with value : T){
        if self.contains(this: Node(value: value)) == false{
            self.append(this: value)
        }
    }
    
    /** Handles the addition of a new node to the linked list*/
    public func append(this value: T){
        let newNode = Node(value: value)
        /** Check to see if a tail node already exists, if it doesn't then make the new node the head and the tail, if a tail node exists then make the new node's previous pointer point to the tail node and the make the tail node's next pointer point to the new node, thus placing the new node in front of the tail node and making the new node the new tail node*/
        if let tailNode = tail{
            newNode.previous = tail
            tailNode.next = newNode
        }
        else{
            head = newNode
        }
        tail = newNode
    }
    
    /**
     Iterate through the linked list node by node until the given index is reached
     - Parameter index: The position within the linked list at which the desired node lies
     - Returns: Node at the given index in the linked list
     */
    public func nodeAt(index: Int) -> Node<T>?{
        if index >= 0{
            var node = head
            var i = index
            
            /** Iterate through all the nodes until you reach the index point aka '0' as you subtract 1 from i until you reach the given, if the index is out of bounds then the linked list will be traversed until the nil pointer at the tail is reached in order to prevent infinite looping*/
            while node != nil{
                if i == 0{return node}
                i -= 1
                node = node!.next
            }
        }
        return nil
    }
    
    /**
     Remove the passed node from the linked list
     - Parameter node: The node that's going to be removed from the linked list
     
     Makes the the next pointer of the previous node equal to the next node that's pointed to by the current node's next pointer and then doing the same but for the previous pointer of the next node of the current node and then setting the pointers of the passed node to nil to mark the entity for deletion*/
    public func remove(this node: Node<T>){
        /** If the previous node exists then make its next pointer point to the node in front of the given node, if it doesn't exist then simply declare the head of the array to the next node of the given node as this implies the current node is the head*/
        if let previous = node.previous{
            previous.next = node.next
        }
        else{
            head = node.next
        }
        /** Make the next node's previous pointer equal to the pointer of the current node's previous pointer*/
        node.next?.previous = node.previous
        
        /** If this node is the tail of the list then make the tail of the array equal to the previous pointer of this node, and if this node is the only element in the array then this statement essentially sets the head and tail to nil effectively deleting the entire list*/
        if node.next == nil{
            tail = node.previous
        }
        
        /**Set both pointers for this node to nil to prevent access to the other nodes within the list thus marking the node for deletion in the memory management cycle as it is inaccessible*/
        node.previous = nil
        node.next = nil
    }
    
    /** Deletes the entire list by setting the head and tail to nil which marks all elements for deletion as they're now inaccessible*/
    public func removeAll(){
        head = nil
        tail = nil
    }
    
    /** Iterate through the entire linked list and print out every single entry alongside the index at which that entry is positioned*/
    public func display(){
        var node = head
        var i = 0
        while node != nil{
            print("Value At Index " + i.description + ":")
            print(node!.value as Any)
            node = node!.next
            i += 1
        }
    }
    
    /** Detect if the given node is contained in the following linked list
     - Parameter node: The node that's going to be removed from the linked list
     - Returns: Bool indicating whether the passed node was found in the list */
    public func contains(this node: Node<T>)->Bool{
        var contained = false
        for index in 0 ..< self.count(){
            if self.nodeAt(index: index)!.equals(node: node){
                contained = true
            }
        }
        return contained
    }
    
    /**
     Swaps the positions of two nodes by interchanging their pointers
     - Parameter i: Index of the first element
     - Parameter j: Index of the second element*/
    public func swapAt(i: Int, j: Int){
        let node1 = nodeAt(index: i)
        let node2 = nodeAt(index: j)
        
        let next1 = node1?.next
        let next2 = node2?.next
        
        let previous1 = node1?.previous
        let previous2 = node2?.previous
        
        if(abs(i-j) > 1){
            node1?.next = next2
            node1?.previous = previous2
            node1?.previous?.next = node1
            node1?.next?.previous = node1
            node2?.next = next1
            node2?.previous = previous1
            node2?.previous?.next = node2
            node2?.next?.previous = node2
        }
        else if(abs(i-j) == 1){
            if(node1!.equals(node: next2)){
                node1?.next = node2
                node1?.previous = previous2
                node2?.next = next1
                node2?.previous = node1
            }
            else{
                node1?.next = next2
                node1?.previous = node2
                node2?.next = node1
                node2?.previous = previous1
            }
            node1?.previous?.next = node1
            node1?.next?.previous = node1
            
            node2?.previous?.next = node2
            node2?.next?.previous = node2
        }
        else{
            return
        }
        
        /** Reset the appropriate head and tail of the list if applicable*/
        if(node1?.next == nil){
            tail = node1
        }
        else if(node2?.next == nil){
            tail = node2
        }
        
        if(node1?.previous == nil){
            head = node1
        }
        else if(node2?.previous == nil){
            head = node2
        }
        
    }
    
    /**Count the total elements present inside of the linked list and return an integer form of this total
     - Returns: Integer representing the total elements present in the current linked list*/
    public func count() -> Int{
        var node = head
        var i = 0
        while node != nil{
            node = node!.next
            i += 1
        }
        return i
    }
    
    /**
     Converts the linked list into an array filled with generic data types 'T'
     - Returns: Array of generic types*/
    public func toArray() -> [T]{
        var genericArray = [T]()
        if(head != nil){
            for i in 0..<self.count(){
                genericArray.append(self.nodeAt(index: i)!.value)
            }
        }
        return genericArray
    }
    
    /**
     Convert an array to a linked list
     - Parameter array: Array filled with generic types
     The linked list is cleared before appending all the new elements from the passed array to avoid conflicting elements
     */
    public func fromArray(array: [T]){
        self.removeAll()
        for element in array{
            self.append(this: element)
        }
    }
    
    /**Reverse the order of the linked list*/
    public func reverse(){
        var node = self.head
        var next = node?.next
        var previous = node?.previous
        while(node != nil){
            node?.next = previous
            node?.previous = next
            self.head = node
            node = next
            next = node?.next
            previous = node?.previous
        }
    }
}
