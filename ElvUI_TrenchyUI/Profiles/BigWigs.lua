-- TrenchyUI/Profiles/BigWigs.lua
local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}

local function CallbackFunction(accepted)
  if not accepted then return end
  local LibStub = _G and rawget(_G, 'LibStub')
  local LDBI = LibStub and LibStub('LibDBIcon-1.0', true)
  if type(BigWigsIconDB) ~= 'table' then BigWigsIconDB = {} end
  BigWigsIconDB.hide = true
  if LDBI then LDBI:Hide('BigWigs') end
end

local profile_str = [[BW1:TzvtRXXrtynm2eYhq0Ukwoj2YizWb8HeSLJtabV4OrALLS1hB2DKTLpn9oBVZ04zNUt39iP14dH9uo4t6KplYVG9GpgclHa(qGH9xqqbm5S4LCoD198LSIomA7Q76PQ65PQEgRFNnDFSqGcWnPcIKqJfFXyCFwy(YhSO7ontTTEH9jXuEFuuXgDC2X1DNTu79YpysgiRqJOCX(DyjCweEPM236R(wl9tNorjgdlcp(A7wbCmo2yXw)0XFak3GDNb4Oi6blzR372DOCuCaEj9Q7QnTih31SwJ4INMLdTXsjjoq8ttZPjYismES76BSYd3zx3n3y7gd7rJLTjphFZjqDUlJH5(ib2BypuxSK0hBFcSXw0yQFiN2hhQjK1uUTnQp(4ghY4QiDaAGgkWw6So(Hiz4OUeblcnaq5IJaV2XKb8SGpkGtpyx2biExr4WebM4RyCVJ9JqcHpqEEfbdYX9AHIibXDwPX2UnADC)YCIvV)aziXVzuIiVI)NJ9PjXYhrj(4XnIdIiIWLMF5(dy1iXcjk2h)q8aXYaKPlWUCvJ3VsInrdtJ4UTv)V7ehsWJjbILMFJ4E0ZcLwVFGT6p2SvTxH8yZvDJDKHy(QjkPKgx4Swtpvh02sex(oHDtACa7tQIsrpyRwBC)1DtV1MZ9BxI95vps7q6blhf1uPgyUW78BMLeQQ0ZqBo4as8hYM5mPRr(sN(SXpxEU75ndTdSPxJtE(8FFcQlhjrZ76YQfd2JqYY2Z)NsauQpq8Rs4yFOGCr8aS0zZgR5YQd7cqwLmNgm6q5DvTu96jWslfX)UOOjX0Lof24XKUYqdS384sN9orIp88iVoMeek1IK4MA)xwWuG2cPW1BCEgz65NaqalR0fOr5(Qbxx1iWM4EsRX5NciSBuSsZt12MkPZ3gflMVfoijcXv0Vp0zqJ6spiE7K(D0Q3SGB)h1O9i44gMypl9I2mKVIFTplsBeVVciC4K88ZKZRFV)(vV6xNAQPw)E)Y1U23n1u2RFV)yU5u)WYEeetd0pXQO0HQOwjZMrvNaguxmOYoaCVk(U37DsjTdEBR9EnUIaAlH(JoB1y1n2Dl2L0GOM(rc1XkcMAIRSSmkPbcis553PLXWuzwww2gpZsdJNzTlNjkLYxLmf0NwTPrKUAzU8AswTZPfxF3MMqvalO(wSpnplBYP(lht6VAchAKITnn3LeM7agUfJCioYWc5oPvzWtpJhA7WX2unvkm6auc5ZPxH9z5hB5ejDfKq2uHaXpsD6SjLCiCv3E(mfkImE6mLu6sM(NYaIJdKHVVPbpVRQr3aS3K8KOYyqTCFxJJ)HeCS)GMxq9kQ7YU65IKUenIt2iBPUUNLwrwflqsG6WHMgR8BL0RY6mSQQ2pjtThcMEkL2hUI9oMtKN8TpGWWEvgGEI1rM9p70S5oHSRqkLNC(TTpkcBFuhKPXt8OjQF6G8FM6vDQRXFqXlSlFCh4iUqQhIuzIUxLNzsh4H5OPgq)ZMn90dOVD)9)r1pSTbVl606QoYBF9RnZWhxV(8v)HnhM6vK8Iop(2S66R5HsV4BDMDil)vjPlKUG1FnsHDXn0xn9JtVYr48q5D6(ebPte2bX3K0NiFZr63odn7P36i8Hmdv9L6llYJHsulqae(ewOd89bEdvoOVdz1PztxCKwyb0q45ayeYbboHJh6GILuvCbMPTCqK6LO4EOKijxKDF3yZNNzsHBpYSsJV8J6eOdSNdaNx6LtNnlZvltxYPhjkkCcU6W7LyZ8oflW4Vj96HP1wyC(Nqb2wGntHNBPsiclIG52LWTfDFC4PfCVPlz2J6LpX8n1521dSQ3XASQ4k)m0rk(jF1ttVy6fFH1)FMH7UHAGghltVWtbf7tQ)Yzs)zwTc4ZfVEG2Lw7ntk2bkRpekav53AF4BKsVX)(d]]

NS.RegisterExternalProfile("BigWigs", function()
  if not NS.IsAddonLoaded("BigWigs") then return false end
  local bigwigsAPI = _G and rawget(_G, 'BigWigsAPI')
  if not bigwigsAPI or not bigwigsAPI.RegisterProfile then return false end

  -- Register profile with BigWigs; BigWigs will prompt and run callback on acceptance
  bigwigsAPI.RegisterProfile('TrenchyUI', profile_str, 'TrenchyUI', CallbackFunction)

  return true
end)
