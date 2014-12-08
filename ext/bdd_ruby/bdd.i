%module "BDD_WRAP"

%{
#include "BDD.h"
#include "ZBDD.h"
%}

%{
static const int power30 = 1 << 30;
static unsigned char BC_BEMII_COUNT = 20;
static bddword Count(BDD, int);
bddword Count(BDD f, int tlev)
{
  if(f == -1) return 0;
  if(f == 0) return 0;

  int var = f.Top();
  int lev = BDD_LevOfVar(var);
  bddword c;
  if(f == 1) c = 1;
  else
  {
    bddword fx = f.GetID();
    c = BDD_CacheInt(BC_BEMII_COUNT, fx, 0);
    if(c > power30)
    {
      BDD_RECUR_INC;
      c = Count(f.At0(var), lev-1) + Count(f.At1(var), lev-1);
      BDD_RECUR_DEC;
      BDD_CacheEnt(BC_BEMII_COUNT, fx, 0, c);
    }
  }
  return c;
}
%}


%rename(assign_bdd)           operator=(const BDD& f);
%rename(and_assign_bdd)       operator&=(const BDD& f);
%rename(bar_assign_bdd)       operator|=(const BDD& f);
%rename(hat_assign_bdd)       operator^=(const BDD& f);
%rename(plus_assign_bdd)      operator+=(const BDD& f);
%rename(minus_assign_bdd)     operator-=(const BDD& f);
%rename(lshift_assign_bdd)    operator<<=(const int s);
%rename(rshift_assign_bdd)    operator>>=(const int s);
%rename(times_assign_bdd)     operator*=(const BDD&);
%rename(divide_assign_bdd)    operator/=(const BDD&);
%rename(remainder_assign_bdd) operator%=(const BDD&);
%rename(lshift_bdd)           operator<<(int s) const;
%rename(rshift_bdd)           operator>>(int s) const;
%rename(times_bdd)            operator*(const BDD&, const BDD&);
%rename(divide_bdd)           operator/(const BDD&, const BDD&);
%rename(hat_bdd)              operator^(const BDD& f, const BDD& g);
%rename(bar_bdd)              operator|(const BDD& f, const BDD& g);
%rename(and_bdd)              operator&(const BDD& f, const BDD& g);
%rename(plus_bdd)             operator+(const BDD& f, const BDD& g);
%rename(minus_bdd)            operator-(const BDD& f, const BDD& g);
%rename(remainder_bdd)        operator%(const BDD& f, const BDD& p);
%rename(equal_bdd)            operator==(const BDD& f, const BDD& g);
%rename(nequal_bdd)           operator!=(const BDD& f, const BDD& g);

%rename(double_bar_bddv)      operator||(const BDDV&, const BDDV&);
%rename(assign_bddv)          operator=(const BDDV& fv);
%rename(and_assign_bddv)      operator&=(const BDDV& fv);
%rename(bar_assign_bddv)      operator|=(const BDDV& fv);
%rename(hat_assign_bddv)      operator^=(const BDDV& fv);
%rename(plus_assign_bddv)     operator+=(const BDDV& fv);
%rename(minus_assign_bddv)    operator-=(const BDDV& fv);
%rename(lshift_assign_bddv)   operator<<=(int);
%rename(rshift_assign_bddv)   operator>>=(int);
%rename(and_bddv)             operator&(const BDDV& fv, const BDDV& gv);
%rename(hat_bddv)             operator^(const BDDV& fv, const BDDV& gv);
%rename(bar_bddv)             operator|(const BDDV& fv, const BDDV& gv);
%rename(plus_bddv)            operator+(const BDDV& fv, const BDDV& gv);
%rename(minus_bddv)           operator-(const BDDV& fv, const BDDV& gv);
%rename(equal_bddv)           operator==(const BDDV& fv, const BDDV& gv);
%rename(nequal_bddv)          operator!=(const BDDV& fv, const BDDV& gv);


%rename(assign_zbdd)           operator=(const ZBDD& f);
%rename(and_assign_zbdd)       operator&=(const ZBDD& f);
%rename(plus_assign_zbdd)      operator+=(const ZBDD& f);
%rename(minus_assign_zbdd)     operator-=(const ZBDD& f);
%rename(lshift_assign_zbdd)    operator<<=(int s);
%rename(rshift_assign_zbdd)    operator>>=(int s);
%rename(times_assign_zbdd)     operator*=(const ZBDD&);
%rename(divide_assign_zbdd)    operator/=(const ZBDD&);
%rename(remainder_assign_zbdd) operator%=(const ZBDD&);
%rename(lshift_zbdd)           operator<<(int s) const;
%rename(rshift_zbdd)           operator>>(int s) const;
%rename(times_zbdd)            operator*(const ZBDD&, const ZBDD&);
%rename(divide_zbdd)           operator/(const ZBDD&, const ZBDD&);
%rename(and_zbdd)              operator&(const ZBDD& f, const ZBDD& g);
%rename(plus_zbdd)             operator+(const ZBDD& f, const ZBDD& g);
%rename(minus_zbdd)            operator-(const ZBDD& f, const ZBDD& g);
%rename(remainder_zbdd)        operator%(const ZBDD& f, const ZBDD& p);
%rename(equal_zbdd)            operator==(const ZBDD& f, const ZBDD& g);
%rename(nequal_zbdd)           operator!=(const ZBDD& f, const ZBDD& g);

%rename(assign_zbddv)          operator=(const ZBDDV& fv);
%rename(and_assign_zbddv)      operator&=(const ZBDDV& fv);
%rename(plus_assign_zbddv)     operator+=(const ZBDDV& fv);
%rename(minus_assign_zbddv)    operator-=(const ZBDDV& fv);
%rename(and_zbddv)             operator&(const ZBDDV& fv, const ZBDDV& gv);
%rename(plus_zbddv)            operator+(const ZBDDV& fv, const ZBDDV& gv);
%rename(minus_zbddv)           operator-(const ZBDDV& fv, const ZBDDV& gv);
%rename(equal_zbddv)           operator==(const ZBDDV& fv, const ZBDDV& gv);
%rename(nequal_zbddv)          operator!=(const ZBDDV& fv, const ZBDDV& gv);

%include "BDD.h"
%include "ZBDD.h"
static bddword Count(BDD, int);
