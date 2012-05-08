from cython.operator cimport dereference as deref, preincrement as inc 
import numpy 
cimport numpy 
cimport cython

cdef extern from "include/SparseMatrixExt.h": 
   cdef cppclass SparseMatrixRowMaj[T]:  
      SparseMatrixRowMaj()
      SparseMatrixRowMaj(int, int)
      int rows() 
      int cols() 
      int size() 
      void insertVal(int, int, T) 
      int nonZeros()
      T coeff(int, int)
      T sum()
      
   cdef cppclass SparseMatrixColMaj[T]:  
      SparseMatrixColMaj()
      SparseMatrixColMaj(int, int)
      int rows() 
      int cols() 
      int size() 
      void insertVal(int, int, T) 
      int nonZeros()
      T coeff(int, int)
      T sum()


cdef class csr_array:
    cdef SparseMatrixRowMaj[double] *thisPtr     
    
    def __cinit__(self, shape): 
        self.thisPtr = new SparseMatrixRowMaj[double](shape[0], shape[1])
             
    def __dealloc__(self):
        del self.thisPtr
        
    def getNDim(self): 
        return 2 
        
    def getShape(self):
        return (self.thisPtr.rows(), self.thisPtr.cols())
        
    def getSize(self): 
        return self.thisPtr.size()    
        
    def getnnz(self): 
        return self.thisPtr.nonZeros()
        
    def __getitem__(self, inds):
        i, j = inds 
        if type(i) == int and type(j) == int: 
            if i < 0 or i>=self.thisPtr.rows(): 
                raise ValueError("Invalid row index " + str(i)) 
            if j < 0 or j>=self.thisPtr.cols(): 
                raise ValueError("Invalid col index " + str(j))      
            return self.thisPtr.coeff(i, j)
        elif type(i) == numpy.ndarray and type(j) == numpy.ndarray: 
            result = numpy.zeros(i.shape[0])
            for ix in range(i.shape[0]): 
                    result[ix] = self.thisPtr.coeff(i[ix], j[ix])
            return result
    """
        elif type(i) == numpy.ndarray and type(j) == slice:
            if j.start == None: 
                start = 0
            else: 
                start = j.start 
            if j.stop == None: 
                stop = self.shape[0]
            else:
                stop = j.start  
            sliceSize = stop - start 
            result = map_array((i.shape[0], sliceSize), 10)
            for ind1 in range(i.shape[0]): 
                for ind2 in range(start, stop): 
                    result[ind1, ind2] = self.thisPtr.get_item(i[ind1], ind2)
            return result
                        
    """
    def __setitem__(self, inds, val):
        i, j = inds 
        if type(i) == int and type(j) == int: 
            if i < 0 or i>=self.thisPtr.rows(): 
                raise ValueError("Invalid row index " + str(i)) 
            if j < 0 or j>=self.thisPtr.cols(): 
                raise ValueError("Invalid col index " + str(j))      
            
            self.thisPtr.insertVal(i, j, val)
        elif type(i) == numpy.ndarray and type(j) == numpy.ndarray: 
            for ix in range(len(i)): 
                self.thisPtr.insertVal(i[ix], j[ix], val)
    
    def put(self, double val, numpy.ndarray[numpy.int32_t, ndim=1] rowInds not None , numpy.ndarray[numpy.int32_t, ndim=1] colInds not None): 
        cdef unsigned int ix 
        for ix in range(len(rowInds)): 
            self.thisPtr.insertVal(rowInds[ix], colInds[ix], val)
            
    def sum(self): 
        return self.thisPtr.sum()
    
    def __str__(self): 
        outputStr = "csr_array " + str(self.shape) + " " + str(self.getnnz()) 
        return outputStr 
    
    shape = property(getShape)
    ndim = property(getNDim)

    