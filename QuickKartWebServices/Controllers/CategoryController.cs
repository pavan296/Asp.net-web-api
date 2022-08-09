using AutoMapper;
using Microsoft.AspNetCore.Mvc;
using QuickKartDataAccessLayer;
using QuickKartDataAccessLayer.Models;
using System;
using System.Collections.Generic;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace QuickKartWebServices.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoryController : ControllerBase
    {
        private readonly QuickKartRepository _repository;
        private readonly IMapper _mapper;

        public CategoryController(QuickKartRepository repository, IMapper mapper)
        {
            _repository = repository;
            _mapper = mapper;
        }
        // GET: api/<CategoryController>
        [HttpGet]
        public JsonResult GetCategories()
        {
            List<Models.Category> categories = new List<Models.Category>();
            try
            {
                List<Categories> categoryList = _repository.GetCategories();
                if(categoryList != null)
                {
                    foreach(var category in categoryList)
                    {
                        Models.Category categoryObj = _mapper.Map<Models.Category>(category);
                        categories.Add(categoryObj);
                    }
                }


            }
            catch(Exception ex)
            {
                categories = null;
            }
            return new JsonResult(categories);
        }

        // GET api/<CategoryController>/5
        [HttpGet("{id}")]
        public string Get(int id)
        {
            return "value";
        }

        // POST api/<CategoryController>
        [HttpPost]
        public void Post([FromBody] string value)
        {
        }

        // PUT api/<CategoryController>/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody] string value)
        {
        }

        // DELETE api/<CategoryController>/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
