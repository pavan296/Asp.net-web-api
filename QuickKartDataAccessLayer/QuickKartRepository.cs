using System;
using System.Collections.Generic;
using System.Text;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using System.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.IO;
using System.Data;
using QuickKartDataAccessLayer.Models;

namespace QuickKartDataAccessLayer
{
    public class QuickKartRepository
    {

        private readonly QuickKartDBContext _context;

        public QuickKartRepository(QuickKartDBContext context)
        {
            _context = context;
        }

        #region Library for MVC/Services Demo

        #region-To get all product details
        public List<Products> GetProducts()
        {
            List<Products> lstProducts = null;
            try
            {
                lstProducts = (from p in _context.Products
                               orderby p.ProductId
                               select p).ToList();
            }
            catch (Exception e)
            {
                lstProducts = null;
            }
            return lstProducts;
        }
        #endregion

        #region-To get a product detail by using ProductId
        public Products GetProductDetails(string productId)
        {
            Products product = new Products();
            try
            {
                product = (from p in _context.Products
                           where p.ProductId.Equals(productId)
                           select p).FirstOrDefault();
            }
            catch (Exception)
            {
                product = null;
            }
            return product;
        }
        #endregion

        #region- To generate new product id
        public string GenerateNewProductId()
        {
            string productId;
            try
            {
                productId = (from p in _context.Products
                             select
  QuickKartDBContext.ufn_GenerateNewProductId()).FirstOrDefault();
            }
            catch (Exception)
            {
                productId = null;
            }
            return productId;
        }
        #endregion

        #region- To add a new product
        public bool AddProduct(Products product)
        {
            bool status = false;
            try
            {
                Products prodObj = new Products();
                prodObj.ProductId = GenerateNewProductId();
                prodObj.ProductName = product.ProductName;
                prodObj.CategoryId = product.CategoryId;
                prodObj.Price = product.Price;
                prodObj.QuantityAvailable = product.QuantityAvailable;
                _context.Products.Add(prodObj);
                _context.SaveChanges();
                status = true;
            }
            catch (Exception ex)
            {
                status = false;
            }
            return status;
        }
        #endregion

        #region- To update the existing product details
        public bool UpdateProduct(Products prod)
        {
            bool status = false;
            try
            {
                var product = (from prdct in _context.Products
                               where prdct.ProductId == prod.ProductId
                               select prdct).FirstOrDefault<Products>();
                if (product != null)
                {
                    product.ProductId = prod.ProductId;
                    product.ProductName = prod.ProductName;
                    product.Price = prod.Price;
                    product.QuantityAvailable = prod.QuantityAvailable;
                    product.CategoryId = prod.CategoryId;
                    _context.SaveChanges();
                    status = true;
                }
            }
            catch (Exception ex)
            {
                status = false;
            }
            return status;
        }
        #endregion

        #region-To delete a existing product
        public bool DeleteProduct(string prodId)
        {
            bool status = false;
            try
            {
                var product = (from prdct in _context.Products
                               where prdct.ProductId == prodId
                               select prdct).FirstOrDefault<Products>();
                _context.Products.Remove(product);
                _context.SaveChanges();
                status = true;
            }
            catch (Exception)
            {
                status = false;
            }
            return status;
        }
        #endregion

        #endregion-Demo

        #region Library for MVC/Services Exercise

        #region-To get all category details
        public List<Categories> GetCategories()
        {
            List<Categories> lstCategories = null;
            try
            {
                lstCategories = (from c in _context.Categories
                                 orderby c.CategoryId ascending
                                 select c).ToList<Categories>();
            }
            catch (Exception)
            {
                lstCategories = null;
            }
            return lstCategories;
        }
        #endregion

        #region get a category detail by using CategoryId
        public Categories GetCategoryDetails(string catId)
        {
            Categories categories = new Categories();
            try
            {
                categories = (from p in _context.Categories
                              where p.CategoryId.Equals(catId)
                              select p).FirstOrDefault();
            }
            catch (Exception)
            {
                categories = null;
            }
            return categories;
        }
        #endregion

        #region-To generate new category id
        public byte GenerateNewCategoryId()
        {
            byte categoryId;
            try
            {
                var newCategoryId = (from p in _context.Categories select QuickKartDBContext.ufn_GenerateNewCategoryId()).FirstOrDefault();
                categoryId = Convert.ToByte(newCategoryId);
            }
            catch (Exception ex)
            {
                categoryId = 0;
            }
            return categoryId;

        }
        #endregion

        #region-To add a new category
        public bool AddCategory(string categoryName)
        {
            bool status = false;
            try
            {
                Categories categories = new Categories();
                categories.CategoryName = categoryName;
                _context.Categories.Add(categories);
                _context.SaveChanges();
                status = true;
            }
            catch (Exception ex)
            {
                status = false;
            }
            return status;
        }
        #endregion

        #region-To update the existing category details
        public bool UpdateCategory(Categories categ)
        {
            bool status = false;
            try
            {
                var category = (from ctgry in _context.Categories
                                where ctgry.CategoryId == categ.CategoryId
                                select ctgry).FirstOrDefault<Categories>();
                //Categories category = context.Categories.Where(e => e.CategoryId == categ.CategoryId).FirstOrDefault<Categories>();
                if (category != null)
                {
                    category.CategoryName = categ.CategoryName;
                    _context.SaveChanges();
                    status = true;
                }
            }
            catch (Exception ex)
            {
                status = false;
            }
            return status;
        }
        #endregion

        #region-To delete a existing category
        public bool DeleteCategory(byte categID)
        {
            bool status = false;
            try
            {
                var category = (from ctgry in _context.Categories
                                where ctgry.CategoryId == categID
                                select ctgry).FirstOrDefault<Categories>();
                _context.Categories.Remove(category);
                _context.SaveChanges();
                status = true;
            }
            catch (Exception)
            {
                status = false;
            }
            return status;
        }
        #endregion

        #endregion
    }
}
