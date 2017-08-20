﻿using System;
using System.Linq.Expressions;

namespace AiTech.LiteOrm.Database
{
    public abstract class SqlMainDataWriter<TEntity, TEntityCollection> : DataWriter<TEntity, TEntityCollection>
        where TEntity : Entity
        where TEntityCollection : EntityCollection<TEntity>, new()
    {
        public SqlMainDataWriter(string username, TEntity item) : base(username, item) { }
        public SqlMainDataWriter(string username, TEntityCollection items) : base(username, items) { }


        public abstract bool SaveChanges();

        protected virtual void CommitChanges()
        {
            _List.CommitChanges();
        }

        protected virtual void RollbackChanges()
        {
            _List.RollbackChanges();
        }


        protected bool Write(Expression<Func<TEntity, string>> ErrorDescription)
        {
            var success = false;

            using (var db = Connection.CreateConnection())
            {
                try
                {

                    db.Open();

                }
                catch (Exception ex)
                {
                    throw new InvalidOperationException("Can not establish connection to server", ex);
                }

                var trn = db.BeginTransaction();
                try
                {

                    success = Write(ErrorDescription, db, trn);

                    trn.Commit();

                    CommitChanges();
                    return success;
                }
                catch
                {
                    trn.Rollback();
                    RollbackChanges();
                    throw;
                }
            }

        }

    }



}